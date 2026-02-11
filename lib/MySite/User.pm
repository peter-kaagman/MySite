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
      $user{'user'}->{'avatar'} = $oauth_data->{$provider}->{'user_info'}->{'picture'};
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
      $user{'user'}->{'avatar'} = $oauth_data->{$provider}->{'user_info'}->{'avatar_url'};
    }
  }
  if (%user){
    # User data processed from OAuth provider
    _checkUser(\%user);
    session->write(%user);
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
  
  debug "Checking/creating user: $username";
  
  my ($db_ok, $found) = db_guard(
    action => "find user by username",
    user => undef,
    code => sub {
      return schema->resultset('User')->find(
        { username => $username },
        {}
      );
    }
  );
  
  unless ($db_ok) {
    error "Database error during user lookup for: $username";
    return template_error(
      title => 'Database Error',
      error => 'Er is een fout opgetreden bij het zoeken van de gebruiker in de database.',
      status => 500
    );
  }
  
  if ($found){
    # Setup user for session from db
    debug "User found in database: $username";
    if ($found->name eq 'unknown'){
      $user->{'user'}->{'name'} = $found->username;
    }else{
      $user->{'user'}->{'name'} = $found->name;
    }
    $user->{'user'}->{'role'} = $found->roleid->name;
    $user->{'user'}->{'avatar'} = $found->avatar;
    $user->{'user'}->{'created'} = $found->created;
    $user->{'user'}->{'source'} = $found->source;
    $user->{'user'}->{'id'} = $found->user_id;
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
        schema->resultset('User')->create($user->{'user'});
        $user->{'user'}->{'role'} = 'Visitor';
        $user->{'user'}->{'name'} = $user->{'user'}->{'username'};
        return 1;
      }
    );
    unless ($create_ok) {
      error "Failed to create new user: $username";
      return;
    }
  }
}

# # Bedoelt voor een gebruiker om zijn eigen profiel te kunnen bewerken
# sub _profile {
#   my $username = route_parameters->get('username');
#   my $user = session->read('user');
#   if ($user && $user->{username} eq $username){
#     debug "Loading own profile for: $username";
#     my ($db_ok, $user_data) = db_guard(
#       action => "fetch user profile",
#       user => $user,
#       code => sub {
#         return schema->resultset('User')->find(
#           { username => $username },
#           {}
#         );
#       }
#     );
    
#     unless ($db_ok) {
#       return template_error(
#         title => 'Profile Error',
#         error => 'Could not load profile',
#         status => 500
#       );
#     }
    
#     if ($user_data){
#       template 'user/profile' => { 
#         'title' => 'Profile '.$username,
#         'user' => $user_data
#       };
#     }else {
#       warning "Profile not found for user: $username";
#       return redirect '/'; # return if not found
#     }
#   }else{
#     warning "Unauthorized profile access attempt";
#     return redirect '/'; # return if not own profile
#   }

# };

# Toont een login pagina, en slaat de return_url op in de session voor na het inloggen
sub _login {
  my $return_url;
  if (request->{'_query_params'}->{'return_url'}){
    $return_url = request->{'_query_params'}->{'return_url'};
  }elsif(request->{'env'}->{'HTTP_REFERER'}){
    $return_url = request->{'env'}->{'HTTP_REFERER'};
  }else{
    $return_url = '/'
  }
  # Haalt de feitelijke login pagina op uit de database, zodat deze makkelijk aan te passen is zonder codewijziging
  session->write('return_url', $return_url);
  my $page =  schema->resultset('Page')->find(
    { name => 'Login'},
    { }
  );
  debug "Login page loaded" if $page;
  template 'page' => {
    'title' => 'Login', 
    'page' => $page,#->get_column('content'),
  };
};


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
    my $params = {
      client_id     => $conf->{client_id},
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
};

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
    my $res = $ua->post($token_url, {
        code          => $code,
        client_id     => $conf->{client_id},
        client_secret => $conf->{client_secret},
        redirect_uri  => $redirect_uri,
        grant_type    => 'authorization_code',
    });
    return template_error(
        title => 'OAuth Error',
        error => 'Token request failed: ' . $res->status_line,
        status => 500
    ) unless $res->is_success;
    my $token = decode_json($res->decoded_content);
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
    my $userinfo_res = $ua->get($userinfo_url . '?access_token=' . uri_escape($access_token));
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


# Routes
prefix '/user' => sub {
  get '/login' => \&_login; # toont login pagina waar een keuze gemaakt kan worden voor OAuth provider
  get '/logout' => \&_logout;
  get '/login/ok' => \&_ok;
  get '/login/failed' => \&_failed;
  # get '/profile/:username' => \&_profile;
};

prefix '/auth' => sub {
  get '/callback/:provider' => \&_auth_callback;
  get '/:provider' => \&_auth_provider;
};

# # OAuth login routes
# get '/user/auth/:provider' => sub {
#     my $provider = route_parameters->get('provider');
#     my $redirect_url = MySite::Provider::OAuth->oauth_redirect($provider);
#     return redirect $redirect_url if $redirect_url;
#     return template_error(
#         title => 'OAuth Error',
#         error => 'Unknown provider or misconfigured',
#         status => 500
#     );
# };

# get '/user/auth/:provider/callback' => sub {
#     my $provider = route_parameters->get('provider');
#     my $code = query_parameters->get('code');
#     my $userinfo = MySite::Provider::OAuth->oauth_callback($provider, $code);
#     if ($userinfo) {
#         session->write('oauth', { $provider => { user_info => $userinfo } });
#         return redirect '/user/login/ok';
#     } else {
#         return redirect '/user/login/failed';
#     }
# };

42;