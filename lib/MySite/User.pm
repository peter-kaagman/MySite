package MySite::User;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Digest::SHA qw(sha256_hex);
use Dancer2::Plugin::DBIC;
use Time::Piece;
use Data::Dumper;
use LWP::UserAgent;
use URI::Escape;
use MySite::ErrorHandler qw(db_guard json_error template_error user_context);



 
sub _ok {
  my $oauth_data = session->read('oauth'); # verwacht data van de provider
  return template_error(
    title => 'OAuth Error',
    error => 'No OAuth data found in session',
    status => 500
  ) unless $oauth_data;
  debug Dumper($oauth_data);
  my %user;
  while (my($provider,$info) = each %{$oauth_data}){
    if ($provider eq 'google') {
      my $email = $oauth_data->{$provider}->{'user_info'}->{'email'};
      unless ($email) {
        return template_error(
          title => 'OAuth Error',
          error => 'Geen e-mailadres ontvangen van Google',
          status => 400
        );
      }
      $user{'user'}->{'source'} = 'google';
      $user{'user'}->{'username'} = $email;
      # $user{'user'}->{'avatar'} = $oauth_data->{$provider}->{'user_info'}->{'picture'};
    } elsif ($provider eq 'github') {
      my $login = $oauth_data->{$provider}->{'user_info'}->{'login'};
      unless ($login) {
        return template_error(
          title => 'OAuth Error',
          error => 'Geen gebruikersnaam ontvangen van GitHub',
          status => 400
        );
      }
      $user{'user'}->{'source'} = 'github';
      $user{'user'}->{'username'} = $login;
      # $user{'user'}->{'avatar'} = $oauth_data->{$provider}->{'user_info'}->{'avatar_url'};
    }
  }
  if (%user){
    # User data processed from OAuth provider
    if (_checkUser(\%user)){
      session->write(%user);
    }else{
      return template_error(
        title => 'User Error',
        error => 'Er is een fout opgetreden bij het verwerken van de gebruiker.',
        status => 500
      );
    }
  }else{
    return template_error(
      title => 'OAuth Error',
      error => 'Geen gebruikersgegevens ontvangen van de OAuth provider',
      status => 400
    );
  }
  my $return_url = session->read('return_url');
  if ($return_url){
    return redirect $return_url;
  }else{
    return redirect '/';
  }
};

sub _failed {
  template 'user/loginfailed' => { 'title' => 'Login failed' };
};

sub _checkUser{
  my $user = shift;
  my $username = $user->{'user'}->{'username'};
  my $source = $user->{'user'}->{'source'};
  
  debug "Checking/creating user: $username vanuit bron: $source";
  
  my ($db_ok, $found) = db_guard(
    action => "find user by username",
    user => undef,
    code => sub {
      return schema->resultset('User')->find(
        { 
          username => $username,
          source => $source
        },
        {}
      );
    }
  );
  
  unless ($db_ok) {
    error "Database error during user lookup for: $username";
    return 0;
    # return template_error(
    #   title => 'Database Error',
    #   error => 'Er is een fout opgetreden bij het zoeken van de gebruiker in de database.',
    #   status => 500
    # );
  }
  
  if ($found){
    # Mag deze gebruiker inloggen? Check of de gebruiker niet gebanned is.
    if ($found->is_banned) {
      error "Gebruiker $username is gebanned en mag niet inloggen.";
      return 0;
      # return template_error(
      #   title => 'Login Error',
      #   error => 'Uw account is geblokkeerd. Neem contact op met de beheerder.',
      #   status => 403
      # );
    }else{
      # Setup user for session from db
      debug "User found in database: $username";
      if ($found->name eq 'unknown'){
        $user->{'user'}->{'name'} = $found->username;
      }else{
        $user->{'user'}->{'name'} = $found->name;
      }
      $user->{'user'}->{'role'} = $found->roleid->name;
      # $user->{'user'}->{'avatar'} = $found->avatar;
      $user->{'user'}->{'created'} = $found->created;
      $user->{'user'}->{'source'} = $found->source;
      $user->{'user'}->{'slug'} = $found->slug;
      $user->{'user'}->{'id'} = $found->user_id;
      return 1;
    }
  }else{
    # Setup a default user for session and db
    info "Creating new Visitor user: $username";
    my ($create_ok) = db_guard(
      action => "create new user",
      user => undef,
      code => sub {
        my $t = localtime;
        my $role = schema->resultset('Role')->find(
          { name => 'Visitor' }
        );
        if (!$role) {
          error "Visitor role not found in database";
          return 0;
        }
        $user->{'user'}->{'created'} = $t->datetime;
        $user->{'user'}->{'roleid'} = $role->role_id;
        $user->{'user'}->{'slug'} =
            MySite::Schema::Result::User->generate_slug(
                schema(),
                $username
            );
        schema->resultset('User')->create($user->{'user'});
        $user->{'user'}->{'role'} = 'Visitor';
        $user->{'user'}->{'slug'} = $user->{'user'}->{'slug'};
        $user->{'user'}->{'name'} = $user->{'user'}->{'username'};
        return 1;
      }
    );
    unless ($create_ok) {
      error "Failed to create new user: $username";
      return 0;
    }
    return 1;
  }
}


sub _auth_provider {
    my $provider = route_parameters->get('provider');
    my $conf = config->{oauth_providers}->{$provider};
    return template_error(
        title => 'OAuth Error',
        error => 'Unknown provider or misconfigured',
        status => 500
    ) unless $conf;
    debug Dumper($conf);
    my $redirect_uri = $conf->{redirect_uri} || uri_for("/auth/callback/$provider");
    my $base = $conf->{authorize_url};
    # Genereer een CSRF state token
    my $state = sha256_hex(rand() . $$ . time());
    session->write('oauth_state', $state);
    # Haal client_id uit ENV indien nodig
    my $client_id;
    $client_id = $ENV{GOOGLE_CLIENT_ID} if $provider eq 'google';
    $client_id = $ENV{GITHUB_CLIENT_ID} if $provider eq 'github';
    my $params = {
      client_id     => $client_id,
      redirect_uri  => $redirect_uri,
      response_type => 'code',
      scope         => $conf->{scope},
      access_type   => 'offline',
      prompt        => 'consent',
      state         => $state,
    };
    my $query = join('&', map { $_ . '=' . uri_escape($params->{$_}) } keys %$params);
    my $url = "$base?$query";
    debug "Redirecting to OAuth provider: $url";
    return redirect $url;
}

sub _auth_callback {
    my $provider = route_parameters->get('provider');
    my $conf = config->{oauth_providers}->{$provider};
    return template_error(
        title => 'OAuth Error',
        error => 'Unknown provider or misconfigured',
        status => 500
    ) unless $conf;
    debug Dumper($conf);
    my $code = query_parameters->get('code');
    my $state = query_parameters->get('state');
    my $expected_state = session->read('oauth_state');
    unless ($state && $expected_state && $state eq $expected_state) {
      return template_error(
        title => 'OAuth Error',
        error => 'CSRF check (state) mislukt',
        status => 400
      );
    }
    return template_error(
      title => 'OAuth Error',
      error => 'No code provided in callback',
      status => 400
    ) unless $code;
    my $redirect_uri = $conf->{redirect_uri} || uri_for("/auth/callback/$provider");
    my $ua = LWP::UserAgent->new;
    my $token_url = $conf->{token_url};
    # Haal client_id en client_secret uit ENV indien nodig
    my $client_id = $ENV{ uc($provider) . '_CLIENT_ID' };
    my $client_secret =  $ENV{ uc($provider) . '_CLIENT_SECRET' };
    # my $client_id = $conf->{client_id};
    # my $client_secret = $conf->{client_secret};
    # $client_id = $ENV{GOOGLE_CLIENT_ID} if $provider eq 'google';
    # $client_secret = $ENV{GOOGLE_CLIENT_SECRET} if $provider eq 'google';
    # $client_id = $ENV{GITHUB_CLIENT_ID} if $provider eq 'github';
    # $client_secret = $ENV{GITHUB_CLIENT_SECRET} if $provider eq 'github';
    my $res = $ua->post(
      $token_url, 
      {
        code          => $code,
        client_id     => $client_id,
        client_secret => $client_secret,
        redirect_uri  => $redirect_uri,
        grant_type    => 'authorization_code',
     }
    );
    return template_error(
        title => 'OAuth Error',
        error => 'Token request failed: ' . $res->status_line,
        status => 500
    ) unless $res->is_success;
debug "Content-Type: " . $res->content_type;
debug "Content: " . $res->decoded_content;
    # my $token = decode_json($res->decoded_content);
    my $token;

    if ( lc($res->content_type) eq 'application/x-www-form-urlencoded') {
      my %token;
      for my $pair (split /&/, $res->decoded_content) {
          my ($k, $v) = split /=/, $pair, 2;
          $token{$k} = uri_unescape($v);
      }
      $token = \%token;
    } else {
        $token = decode_json($res->decoded_content);
    }
    debug "Token" . Dumper($token);

    if ($token->{error}) {
      return template_error(
        title => 'OAuth Error',
        error => 'Token error: ' . ($token->{error_description} // $token->{error}),
        status => 500
      );
    }
    my $access_token = $token->{access_token} or return template_error(
      title => 'OAuth Error',
      error => 'No access_token in response',
      status => 500
    );
    # Haal userinfo op
    my $userinfo_url = $conf->{userinfo_url};
    # my $userinfo_res = $ua->get($userinfo_url . '?access_token=' . uri_escape($access_token));

my $userinfo_res = $ua->get(
    $userinfo_url,
    'Authorization' => "Bearer $access_token",
    'Accept'        => 'application/json',
);

debug "userinfo url: $userinfo_url";
debug "userinfo status: " . $userinfo_res->status_line;
debug "userinfo content-type: " . ($userinfo_res->content_type // '<undef>');
debug "userinfo body: " . $userinfo_res->decoded_content;



    return template_error(
      title => 'OAuth Error',
      error => 'Userinfo request failed: ' . $userinfo_res->status_line,
      status => 500
    ) unless $userinfo_res->is_success;
    my $userinfo = decode_json($userinfo_res->decoded_content);
    if ($userinfo->{error}) {
      return template_error(
        title => 'OAuth Error',
        error => 'Userinfo error: ' . ($userinfo->{error_description} // $userinfo->{error}),
        status => 500
      );
    }
    if ($userinfo) {
      session->write('oauth', { $provider => { user_info => $userinfo } });
      return redirect '/user/login/ok';
    } else {
      return redirect '/user/login/failed';
    }
};

sub _logout{
  app->destroy_session;
  return redirect '/';
};



42;