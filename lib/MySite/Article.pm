package MySite::Article;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use Template;
use FindBin;
use Time::Piece;
# use Text::Markdown 'markdown';
use String::Util qw(trim);
use MySite::Utils qw(render_markdown);


sub _slugify {
  my ($text) = @_;
  $text //= '';
  $text = lc $text;
  $text =~ s/[^a-z0-9]+/-/g;
  $text =~ s/^-+|-+$//g;
  $text = 'artikel' unless length $text;
  return $text;
}

sub _unique_slug {
  my ($base_text) = @_;
  my $base = _slugify($base_text);
  my $slug = $base;
  my $counter = 2;

  while (schema->resultset('Article')->find({ slug => $slug })) {
    $slug = $base . '-' . $counter;
    $counter++;
  }

  return $slug;
}




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
    my @keywords = $article->keywords->all;
    my @keyword_data = map { { title => $_->title, id => $_->keyword_id } } @keywords;
    debug Dumper \@keyword_data;
    # debug "Keywords: ", join(', ', map { $_->{title} } @keyword_data);
    # debug Dumper \@keyword_data;

    # Category
    my $category_obj = $article->categoryid;
    my $category_data = { title => $category_obj->title, id => $category_obj->category_id };
    debug "Categorie: ", Dumper $category_data;

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

      # debug $author->first->username if $author->first->username;
      # debug Dumper $article;
      template 'article/edit' => {
        'title' => $article->title,
        'user' => session->read('user'),
        'article' => $article,
        'article_content' => $content,
        'author' => $author->first,
        'content_count' => $content_count,
        'keywords' => to_json(\@keyword_data),
        'category' => to_json($category_data),
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
      status 200;
      content_type 'application/json';
      return to_json({ 
        success => 1,
        content => trim($data->{value}),
        version => $newVersion,
        message => "Content updated successfully"
      });
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
      status 200;
      content_type 'application/json';
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
      status 200;
      content_type 'application/json';
      return to_json({ 
        success => 1,
        route_parameters->get('field')  => trim($data->{value}),
        message => "Field " . route_parameters->get('field') . " updated successfully"
      });
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

    my $categories = schema->resultset('Category')->search(
      {},
      { order_by => { '-asc' => 'title' } }
    );

    template 'article/add' => {
      'title' => "New article",
      'user'  => session->read('user'),
      'categories' => $categories,
    }
  } else {
    # User is not valid => show error
    my $username = $user ? $user->{'username'} : 'unknown';
    debug "New article not allowed for user ", $username;
    template 'error' => {
      'title'         => "New article error",
      'user'          => session->read('user'),
      'error_content' => "Creating new article not allowed.",
    }
  }
}

sub _post_article_new {
  my $user = session->read('user');
  unless ($user && ($user->{role} eq 'Admin' || $user->{role} eq 'Editor' || $user->{role} eq 'Writer')) {
    status 403;
    return { success => 0, error => 'Alleen admins, editors en auteurs mogen artikelen toevoegen.' };
  }

  my $params;
  eval { $params = from_json(request->body); 1 } or do {
    status 400;
    return { success => 0, error => 'Ongeldige JSON payload.' };
  };

  my $title      = trim($params->{title} // '');
  my $slug_input = trim($params->{slug} // '');
  my $slugtitle  = exists $params->{slugtitle} ? ($params->{slugtitle} ? 1 : 0) : 1;
  my $abstract   = trim($params->{abstract} // '');
  my $content    = trim($params->{content} // '');
  my $categoryid = $params->{categoryid};
  my $published  = $params->{published};

  my @missing;
  push @missing, 'title'     unless length $title;
  push @missing, 'abstract'  unless length $abstract;
  push @missing, 'content'   unless length $content;
  push @missing, 'category'  unless $categoryid;
  if (@missing) {
    status 400;
    return { success => 0, error => 'Ontbrekende velden: ' . join(', ', @missing) };
  }

  my $category = schema->resultset('Category')->find($categoryid);
  unless ($category) {
    status 400;
    return { success => 0, error => 'Ongeldige categorie.' };
  }

  my $slug = _unique_slug(length $slug_input ? $slug_input : $title);

  my $article;
  eval {
    $article = schema->resultset('Article')->create({
      title      => $title,
      slug       => $slug,
      slugtitle  => $slugtitle,
      authorid   => $user->{id},
      categoryid => $category->category_id,
      abstract   => $abstract,
      published  => $published,
    });

    $article->create_related('article_contents', {
      content  => $content,
      version  => 1,
      editorid => $user->{id},
    });
  };

  if ($@ || !$article) {
    warning "Error creating article: $@";
    status 500;
    return { success => 0, error => 'Artikel kon niet worden opgeslagen.' };
  }

  status 201;
  return {
    success => 1,
    id      => $article->article_id,
    slug    => $article->slug,
    category_slug => $category->slug,
    url     => $article->returnURL(),
  };
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
        return to_json({ error => "Database error: $@" });
    }else{
        warning "Keyword handled successfully";
        status 200;
        return to_json({ result => "Ok"});
    }
}

sub _handle_category {
  my $data = from_json(request->body);
  debug Dumper $data;

  eval {
    my $article = schema->resultset('Article')->find($data->{article_id});
    if ($data->{checked}) {
      debug "Set category: $data->{category} for article: $data->{article_id}";
      my $category = schema->resultset('Category')->find_or_create({ title => $data->{category} });
      $article->update({ categoryid => $category->category_id });
    } else {
      # Single-select UI: unchecked events are ignored
      debug "Category change unchecked/ignored for article: $data->{article_id}";
    }
  };

  content_type 'application/json';
  if ($@) {
    warning "DBIC error: $@";
    status 500;
    return to_json({ error => "Database error: $@" });
  } else {
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
  return to_json({ values => \@keywords_list });
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
  # debug "Categories: ", join(', ', @category_list);
  content_type 'application/json';
  return to_json({ values => \@category_list });
}



prefix '/article' => sub {
  get '/keywords' => \&_get_keywords;
  get '/categories' => \&_get_categories;
  get '/new' => \&_get_article_new;
  get '/edit/:id' => \&_get_article_edit;
  get '/delete/:id' => \&_article_delete;
  get '/:category/:slug' => \&_article;
  post '/add' => \&_post_article_new;
  post '/update/:field/:id' => \&_field_update;
  post '/keyword' => \&_handle_keyword;
  post '/category' => \&_handle_category;
};

42;