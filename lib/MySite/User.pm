package MySite::User;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::Auth::OAuth;
# use Dancer2::Plugin::Auth::Tiny;
# use Dancer2::Plugin::Database;
use Dancer2::Plugin::DBIC;
# use DateTime;
use Time::Piece;
use Data::Dumper;
use Switch;
use MySite::ErrorHandler qw(db_guard json_error template_error user_context);

debug "Google callback_url: " . (config->{plugins}->{'Auth::OAuth'}{providers}{Google}{callback_url} // '[not set]');
debug "Github callback_url: " . (config->{plugins}->{'Auth::OAuth'}{providers}{Github}{callback_url} // '[not set]');


sub _login {
  my $return_url;
  if (request->{'_query_params'}->{'return_url'}){
    $return_url = request->{'_query_params'}->{'return_url'};
  }elsif(request->{'env'}->{'HTTP_REFERER'}){
    $return_url = request->{'env'}->{'HTTP_REFERER'};
  }else{
    $return_url = '/'
  }
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

sub _logout{
  app->destroy_session;
  return redirect '/';
};

sub _ok {
  my $oauth_data = session->read('oauth');
  my %user;
  while (my($provider,$info) = each %{$oauth_data}){
    switch ($provider){
      case 'google' {
        $user{'user'}->{'source'} = 'google';
        $user{'user'}->{'username'} = $oauth_data->{$provider}->{'user_info'}->{'email'};
        $user{'user'}->{'avatar'} = $oauth_data->{$provider}->{'user_info'}->{'picture'};
      }
      case 'github' {
        $user{'user'}->{'source'} = 'github';
        $user{'user'}->{'username'} = $oauth_data->{$provider}->{'user_info'}->{'login'};
        $user{'user'}->{'avatar'} = $oauth_data->{$provider}->{'user_info'}->{'avatar_url'};
      }
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
    return;
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

# Bedoelt voor een gebruiker om zijn eigen profiel te kunnen bewerken
sub _profile {
  my $username = route_parameters->get('username');
  my $user = session->read('user');
  if ($user && $user->{username} eq $username){
    debug "Loading own profile for: $username";
    my ($db_ok, $user_data) = db_guard(
      action => "fetch user profile",
      user => $user,
      code => sub {
        return schema->resultset('User')->find(
          { username => $username },
          {}
        );
      }
    );
    
    unless ($db_ok) {
      return template_error(
        title => 'Profile Error',
        error => 'Could not load profile',
        status => 500
      );
    }
    
    if ($user_data){
      template 'user/profile' => { 
        'title' => 'Profile '.$username,
        'user' => $user_data
      };
    }else {
      warning "Profile not found for user: $username";
      return redirect '/'; # return if not found
    }
  }else{
    warning "Unauthorized profile access attempt";
    return redirect '/'; # return if not own profile
  }

};


# Routes
prefix '/user' => sub {
  get '/login' => \&_login;
  get '/logout' => \&_logout;
  get '/login/ok' => \&_ok;
  get '/login/failed' => \&_failed;
  get '/profile/:username' => \&_profile;
};

42;