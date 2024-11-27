package MySite;

use utf8;
use Dancer2;
use Dancer2::Plugin::Auth::OAuth;
use Dancer2::Plugin::Auth::Tiny;
# use Dancer2::Plugin::Database;
use Dancer2::Plugin::DBIC;
use DateTime;
use Data::Dumper;
use Switch;

our $VERSION = '0.1';

$ENV{DBIC_TRACE} = '1';

get '/' => sub {
  my $articles = schema->resultset('Article')->search(
    {},
    {
      order_by => {'-desc' => ['created']},
    }
  );
  #debug schema.resultset('Article')->returnURL(2);
  template 'index' => { 
    'title' => 'MySite',
    'user' => session->read('user'),
    'articles' => $articles
  };
};

get '/article/:category/:slug' => sub {
  my $article = schema->resultset('Article')->find(
    {
      slug => route_parameters->get('slug')
    },{}
  );
  debug $article->title;

  my $content = $article->search_related(
    'article_contents',
    {},
    {
        order_by => {'-desc' => ['version']},
        rows => 1,
        page => 1

    }
  );
  debug $content->first->version;

  template 'article' => {
    'title' => $article->title,
    'user' => session->read('user'),
    'article' => $article,
    'article_content' => $content, 
  }
};


get '/secured' => needs login => sub {
  my $user = session->read('user');
  debug "Dit is secured";
  debug Dumper $user;
  template 'index' => {
    'title' => 'Secured',
    'user' => session->read('user')

  };
};

get '/login' => sub {
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
  debug "Wat is page";
  debug $page->name;
  template 'page' =>{
    'title' => 'Login', 
    'page' => $page,#->get_column('content'),
  };
};

get '/logout' => sub {
  app->destroy_session;
  return redirect '/';
};

get '/login/ok' => sub {
  my $oauth_data = session->read('oauth');
  my %user;
  while (my($provider,$info) = each %{$oauth_data}){
    switch ($provider){
      case 'google' {
        $user{'user'}->{'source'} = 'google';
        $user{'user'}->{'sourceuser'} = $oauth_data->{$provider}->{'user_info'}->{'email'};
        $user{'user'}->{'avatar'} = $oauth_data->{$provider}->{'user_info'}->{'picture'};
      }
      case 'github' {
        $user{'user'}->{'source'} = 'github';
        $user{'user'}->{'sourceuser'} = $oauth_data->{$provider}->{'user_info'}->{'login'};
        $user{'user'}->{'avatar'} = $oauth_data->{$provider}->{'user_info'}->{'avatar_url'};
      }
    }
  }
  if (%user){
    #debug Dumper \%user;
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

get '/login/failed' => sub {
  template 'loginfailed' =>{ 'title' => 'Login failed'};
};

sub _checkUser{
  my $user = shift;
  debug "Searching for:";
  debug Dumper $user;
  my $found = schema->resultset('User')->find(
    {
      sourceuser => $user->{'user'}->{'sourceuser'}
    },{}
  );
  if ($found){
    debug "Found";
    $user->{'user'}->{'role'} = $found->roleid->name;
  }else{
    debug "Not found";
    my $role = schema->resultset('Role')->find(
      {
        name => 'Visitor'
      }
    );
    $user->{'user'}->{'name'} = 'Peter';
    $user->{'user'}->{'created'} = '2014-11-25 21:10';
    $user->{'user'}->{'roleid'} = $role->role_id;
    debug Dumper $user;
    schema->resultset('User')->create($user->{'user'});
  }
}

true;
