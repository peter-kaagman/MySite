package MySite::Article;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite';
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use Template;
use FindBin;
use Time::Piece;




sub _article {
  my $article = schema->resultset('Article')->find(
    {
      slug => route_parameters->get('slug')
    },{}
  );
  # debug $article->title;
  my $content = $article->search_related(
    'article_contents',
    {},
    {
        order_by => {'-desc' => ['version']},
        rows => 1,
        page => 1

    }
  );
  # debug $content->first->version;
  template 'article/article' => {
    'title' => $article->title,
    'user' => session->read('user'),
    'article' => $article,
    'article_content' => $content, 
  }
}

sub _article_edit {
  # Ff wat gegevens ophalen van het artikel
  my $article = schema->resultset('Article')->find(
    {
      article_id => route_parameters->get('id')
    },{}
  );
  # Autheur voor authorisatie
  my $author = $article->search_related('authorid');
  # Logged in user
  my $user = session->read('user');

  # Toestaan voor Admin of eigenaar
  if (
    $user->{'username'} &&  # Is er uberhaupt iemand aangemeld?
    ( 
      $user->{'role'} eq 'Admin' ||
      ( $author->first->username && $user->{'username'} eq $author->first->username ) 
    )
  ){
    say "Edit ", route_parameters->get('id');
    # Get the article content
    my $content = $article->search_related(
      'article_contents',
      {},
      {
          order_by => {'-desc' => ['version']},
          rows => 1,
          page => 1

      }
    );
    # say $author->first->username if $author->first->username;
    say Dumper $user;
    template 'article/edit' => {
      'title' => $article->title,
      'user' => session->read('user'),
      'article' => $article,
      'article_content' => $content
    }
  }else{
    say "Edit not allowed", route_parameters->get('id');
    # say $author->first->username;
    say Dumper $user;
    template 'error' => {
      'title' => $article->title . " error",
      'user' => session->read('user'),
      'error_content' => "Editing not allowed by user ". session->read('user'), 
    }
  }
}

sub _article_update {
  say "Update ", route_parameters->get('id');
  # Ff wat gegevens ophalen van het artikel
  my $article = schema->resultset('Article')->find(
    {
      article_id => route_parameters->get('id')
    },{}
  );
  # Autheur voor authorisatie
  my $author = $article->search_related('authorid');
  # Logged in user
  my $user = session->read('user');
  # print Dumper $user;

  # Toestaan voor Admin of eigenaar
  response_header('Content-Type' => 'application/json');
  if (
    $user->{'username'} &&  # Is er uberhaupt iemand aangemeld?
    ( 
      $user->{'role'} eq 'Admin' ||
      ( $author->first->username && $user->{'username'} eq $author->first->username ) 
    )
  ){
    my $data = from_json( request->body );
    say $data->{content};
    # say body_parameters->get('content');

    # Get the article content
    my $content = $article->search_related(
      'article_contents',
      {},
      {
          order_by => {'-desc' => ['version']},
          rows => 1,
          page => 1

      }
    );
    my $t = localtime;
    my $newVersion = $content->first->version() + 1;
    $content->create({
      content => $data->{content},
      version => $newVersion,
      editorid => $user->{'id'},
      created => $t->datetime,
      published => $content->first->published()
    });
    status(200);
  }else{
    status(401)
  }
}

sub _article_delete {
  say "Delete ", route_parameters->get('id');
  say "Not implemented yet";
  return redirect '/';
}


prefix '/article' => sub {
    get '/edit/:id' => \&_article_edit;
    post '/update/:id' => \&_article_update;
    get '/delete/:id' => \&_article_delete;
    get '/:category/:slug' => \&_article;
};


42;