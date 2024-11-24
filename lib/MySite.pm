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

# $ENV{DBIC_TRACE} = '1';

get '/' => sub {
  my $articles = schema->resultset('Article')->search(
    {},
    {
      order_by => {'-desc' => ['created']},
    }
  );
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
  my $page =  schema->resultset('Page')->search(
    { name => 'Login'},
    {
      join => 'page_contents',
      '+select' => ['page_contents.content'],
      '+as' => ['content']
    }
  )->single();
  debug "Wat is page";
  debug $page->name;
  debug $page->get_column('content');
  # foreach my $page ($pages->all){
  #   debug $page->name;
  # }
  # my $sth = database->prepare("Select content From pages Where id =?");
  # $sth->execute('login');
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
        $user{'user'}->{'bron'} = 'google';
        $user{'user'}->{'userid'} = $oauth_data->{$provider}->{'user_info'}->{'email'};
        $user{'user'}->{'picture'} = $oauth_data->{$provider}->{'user_info'}->{'picture'};
      }
      case 'github' {
        $user{'user'}->{'bron'} = 'github';
        $user{'user'}->{'userid'} = $oauth_data->{$provider}->{'user_info'}->{'login'};
        $user{'user'}->{'picture'} = $oauth_data->{$provider}->{'user_info'}->{'avatar_url'};
      }
    }
  }
  if (%user){
    debug Dumper \%user;
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
  my $blaat = schema->resultset('User')->find($user);
  print Dumper $blaat;
  # Bestaat deze gebruiker al?
  # my $sth = database->prepare("Select * From users Where id = ?");
  # $sth->execute($user->{'user'}->{'userid'});
  # my $result = $sth->fetchrow_hashref();
  # $sth->finish();
  # if ($result){
  #   $user->{'user'}->{'role'} = $result->{'role'};
  # }else{
  #   $sth = database->prepare('Insert Into users (id,avatar,bron,role) values (?,?,?,?) ');
  #   $user->{'user'}->{'role'} = 'visitor';
  #   $sth->execute(
  #     $user->{'user'}->{'userid'},
  #     $user->{'user'}->{'picture'},
  #     $user->{'user'}->{'bron'},
  #     $user->{'user'}->{'role'}
  #   );
  #   $sth->finish();
  # }

  $user->{'user'}->{'role'} = 'visitor';
}

true;
