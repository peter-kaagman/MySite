package MySite::Article;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite';
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use Template;
use FindBin;
use Time::Piece;
# use Text::Markdown 'markdown';
use String::Util qw(trim);
use MySite::Utils qw(render_markdown);




sub _article {
  my $article = schema->resultset('Article')->find(
    {
      slug => route_parameters->get('slug')
    },{}
  );
  # Autheur voor authorisatie (to show edit and delete links)
  my $author = $article->search_related('authorid');
  # debug $author->first->username if $author->first;
  my $content = $article->search_related(
    'article_contents',
    {},
    {
        order_by => {'-desc' => ['version']},
        rows => 1,
        page => 1

    }
  );
  
  # my $content_html = markdown($content->first->content || '');
  # debug Dumper $content->first;
  # debug $content->first->content;
  # debug $content->first->version;
  # debug "Content HTML: ", $content_html;
  # debug  $article;
  template 'article/article' => {
    'title' => $article->title,
    'user' => session->read('user'),
    'author' => $author->first,
    'article' => $article,
    'article_content' => $content->first->content,
    'render_markdown' => \&MySite::Utils::render_markdown,
  }
}
sub _get_article_edit {
  # Logged in user
  my $user = session->read('user');
  # debug Dumper $user;

  # Als er geen user is, dan terug naar home
  if (!$user || !$user->{'username'}) {
    debug "No user found, redirecting to home";
    return redirect '/';
  }else {
    my ($article, $authorUsername);
    
    # Ff wat gegevens ophalen van het artikel
    $article = schema->resultset('Article')->find(
      {
        article_id => route_parameters->get('id')
      },{}
    );

    # Version count
    my $content_count = $article->search_related('article_contents')->count;
    # debug "Content count: ", $content_count;

    # Keywords
    my @keywords = $article->keywords->get_column('title')->all;

    # Autheur voor authorisatie
    my $author = $article->search_related('authorid');
    # $authorUsername = $author->first->username() if $author->first;
    # debug "Author: ", $authorUsername ;


    # (1, 'Admin'),
    # (2, 'Editor'),
    # (3, 'Writer'),
    # (4, 'Visitor')
    # Toestaan voor Admin, editor of eigenaar
    if ( 
      $user->{'username'} eq $author->first->username() ||
      $user->{'role'} eq 'Editor' ||
      $user->{'role'} eq 'Admin' 
    ){
      debug "Edit ", route_parameters->get('id');
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
      # my $categories = schema->resultset('Category')->find({},{} );
      my $categories = schema->resultset('Category')->search(
        {},
        {
            order_by => {'-desc' => ['title']},
        }
      );

      # debug $author->first->username if $author->first->username;
      # debug Dumper $article;
      template 'article/edit' => {
        'title' => $article->title,
        'user' => session->read('user'),
        'article' => $article,
        'article_content' => $content,
        'categories' => $categories,
        'author' => $author->first,
        'content_count' => $content_count,
        'keywords' => \@keywords,
        'page' => 'article_edit',
      }
    }else{
      debug "Edit not allowed", route_parameters->get('id');
      # debug $author->first->username;
      debug Dumper $user;
      template 'error' => {
        'title' => $article->title . " error",
        'user' => session->read('user'),
        'error_content' => "Editing not allowed by user ". session->read('user'), 
      }
    }
  }
}
sub _field_update {
  # debug "Update veld ", route_parameters->get('field');
  # debug "Van id ", route_parameters->get('id');

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

  response_header('Content-Type' => 'application/json');

  # Toestaan voor Admin, editor of eigenaar
  if ( 
    $user->{'username'} eq $author->first->username() ||
    $user->{'role'} eq 'Editor' ||
    $user->{'role'} eq 'Admin' 
  ){
    my $data = from_json( request->body );
    # debug $data->{value};
    # $article->(route_parameters->get('field'))($data->{value});

    # For content, we need to create a new version
    if (route_parameters->get('field') eq 'content') {
      debug "Update content with value ", $data->{value};

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
        content => trim($data->{value}),
        version => $newVersion,
        editorid => $user->{'id'},
        created => $t->datetime,
        # published => $content->first->published()
      });
      return to_json({ 
        success => 1,
        content => trim($data->{value}),
        version => $newVersion,
        message => "Content updated successfully"
      });
      status(200);
      # status(418); # 418 I'm a teapot, because this is not implemented yet
    }elsif(
      # If title and slug are linked, we update both
      (route_parameters->get('field') eq 'title') &&
      ($article->{'slugtitle'} = '1')
    ){
      # Update title and slug if slugtitle is set to 1
      debug "Update title and slug ";
      $article->update({
        title => trim($data->{value}),
        slug => lc(trim($data->{value})) =~ s/\s+/_/gr
      });
      # status(200);
      return to_json({ 
        success => 1,
        slug => $article->slug, 
        title => $article->title,
        message => "Title and slug updated successfully"
      });
    }else{
      debug "Generic Update field ", route_parameters->get('field'), " with value ", $data->{value};
      $article->update({
        route_parameters->get('field') => trim($data->{value})
      });
      return to_json({ 
        success => 1,
        route_parameters->get('field')  => trim($data->{value}),
        message => "Field " . route_parameters->get('field') . " updated successfully"
      });
      # status(200);
    };
  }else{
    status(401)
  }
}

sub _article_delete {
  debug "Delete ", route_parameters->get('id');
  debug "Not implemented yet";
  return redirect '/';
}

sub _get_article_new {
  my $user = session->read('user');
  # (1, 'Admin'),
  # (2, 'Editor'),
  # (3, 'Writer'),
  # (4, 'Visitor')
  # Check for valid user
  if ( ($user) && ($user->{'role'} eq 'Admin' || $user->{'role'} eq 'Editor' || $user->{'role'} eq 'Writer') ) {
    debug "User is allowed";
    # Valid user => serve template
    template 'article/add' => {
      'title' => "New article",
      'user'  => session->read('user')
    }
  } else {
    # User is not valid => show error
    debug "New article not allowed for user ", $user->{'username'};
    template 'error' => {
      'title'         => "New article error",
      'user'          => session->read('user'),
      'error_content' => "Creating new article not allowed.",
    }
  }
}

sub _post_article_new {
    my $user = session->read('user');
    unless ($user && ($user->{role} eq 'Admin' || $user->{role} eq 'Writer')) {
        status 403;
        return to_json({ success => 0, error => 'Alleen admins en auteurs mogen artikelen toevoegen.' });
    }
    my $params = from_json(request->body);
    my $title   = $params->{title};
    my $content = $params->{content};
    unless ($title && $content) {
        status 400;
        return to_json({ success => 0, error => 'Titel en inhoud zijn verplicht.' });
    }
    my $article = schema->resultset('Article')->create({
        title   => $title,
        content => $content,
        authorid => $user->{id},
    });
    return to_json({ success => 1, id => $article->id });
}

sub _handle_keyword {
    my $data = from_json(request->body);
    debug Dumper $data;
    eval{
        if ($data->{checked}) {
            debug "Add keyword: $data->{keyword} to article: $data->{article_id}";
            my $article = schema->resultset('Article')->find($data->{article_id});
            my $keyword  = schema->resultset('Keyword')->find_or_create({ title => $data->{keyword} });
            $article->add_to_keywords($keyword);
        }else{
            debug "Remove keyword: $data->{keyword} from article: $data->{article_id}";
            my $article = schema->resultset('Article')->find($data->{article_id});
            my $keyword = schema->resultset('Keyword')->find({ title => $data->{keyword} });
            if ($keyword) {
                $article->remove_from_keywords($keyword);
            }
        }
    };

    content_type 'application/json';
    if ($@) {
        warning "DBIC error: $@";
        status 500;
        # return to_json({ error => "Database error: $@" });
    }else{
        status 200;
        return to_json({ result => "Ok"});
    }
}

sub _get_keywords {
  my $keywords = schema->resultset('Keyword')->search(
      {
        title => { 
          -like => query_parameters->get('query') ? '%'.query_parameters->get('query').'%': '%'
          },
      },
      {
          order_by => {'-desc' => ['title']},
      }
  );
  my @keywords_list = map { $_->title } $keywords->all;
  # debug "Keywords: ", join(', ', @keywords_list);
  content_type 'application/json';
  return to_json({ vallues => \@keywords_list });
}

sub _get_categories {
  my $categories = schema->resultset('Category')->search(
      {
        title => { 
          -like => query_parameters->get('query') ? '%'.query_parameters->get('query').'%': '%'
          },
      },
      {
          order_by => {'-desc' => ['title']},
      }
  );
  my @category_list = map { $_->title } $categories->all;
  debug "Categories: ", join(', ', @category_list);
  content_type 'application/json';
  return to_json({ values => \@category_list });
}

prefix '/article' => sub {
  get '/keywords' => \&_get_keywords;
  get '/categories' => \&_get_categories;
  get '/new' => \&_get_article_new;
  post '/add' => \&_post_article_new;
  get '/edit/:id' => \&_get_article_edit;
  post '/update/:field/:id' => \&_field_update;
  get '/delete/:id' => \&_article_delete;
  get '/:category/:slug' => \&_article;
  post '/keyword' => \&_handle_keyword;
};

42;