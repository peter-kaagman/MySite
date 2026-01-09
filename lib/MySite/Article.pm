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
use MySite::Utils qw(render_markdown require_user_logged_in user_can_edit_article slugify unique_slug);

# Route handlers

# geen auth check nodig
sub _article {
  # Iedereen kan artikelen bekijken, dus geen user check nodig
  my $article = schema->resultset('Article')->find(
    {
      slug => route_parameters->get('slug')
    },{}
  );
  
  unless ($article) {
    debug "Article not found in _article ", route_parameters->get('slug');
    return template 'error' => {
      'title' => "Article not found",
      'user' => session->read('user'),
      'error_content' => "Article not found.",
    };
  }
  
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

# heeft auth check
sub _get_article_edit {
  # start auth check
  my $user = session->read('user');
  unless ($user) {
    debug "No user", route_parameters->get('id');
    return template 'error' => {
      'title' => "No user error",
      'user' => 'unknown',
      'error_content' => "Need to be logged in to edit articles.",
    };
  }
  my $article = schema->resultset('Article')->find({ article_id => route_parameters->get('id') }, {});
  unless ($article) {
    debug "Article not found in _get_article_edit ", route_parameters->get('id');
    return template 'error' => {
      'title' => "Article not found",
      'user' => session->read('user'),
      'error_content' => "Article not found.",
    };
  }
  my $author_obj = $article->search_related('authorid')->first;
  # (1, 'Admin'),
  # (2, 'Editor'),
  # (3, 'Writer'),
  # (4, 'Visitor')
  my @allowed_roles = qw(Admin Editor Owner);
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    debug "Edit not allowed", route_parameters->get('id'), 'User:', $user->{username};
    return template 'error' => {
      'title' => $article->title . " error",
      'user' => session->read('user'),
      'error_content' => "Editing not allowed by user " . session->read('user'),
    };
  }
  # end auth check
  
  # Process article data for edit template
  my $content_count = $article->search_related('article_contents')->count;
  my @keywords = $article->keywords->all;
  my @keyword_data = map { { title => $_->title, id => $_->keyword_id } } @keywords;
  debug Dumper \@keyword_data;

  my $category_obj = $article->categoryid;
  my $category_data = { title => $category_obj->title, id => $category_obj->category_id };
  debug "Categorie: ", Dumper $category_data;

  my $content = $article->search_related(
    'article_contents',
    {},
    {
        order_by => {'-desc' => ['version']},
        rows => 1,
        page => 1

    }
  );

  debug "Edit ", route_parameters->get('id');

  template 'article/edit' => {
    'title' => $article->title,
    'user' => session->read('user'),
    'article' => $article,
    'article_content' => $content,
    'author' => $author_obj,
    'content_count' => $content_count,
    'keywords' => to_json(\@keyword_data),
    'category' => to_json($category_data),
    'page' => 'article_edit',
  }
}

# heeft auth check
sub _field_update {
  # Start auth check
  my $user = session->read('user');
  unless ($user) {
    status 401;
    return to_json({ error => 'Unauthorized' });
  } 

  # Ff wat gegevens ophalen van het artikel
  my $article = schema->resultset('Article')->find(
    {
      article_id => route_parameters->get('id')
    },{}
  );
  unless ($article) {
    debug "Article not found", route_parameters->get('id');
    status 404;
    return to_json({ error => 'Article not found' });
  }
  
  my $author_obj = $article->search_related('authorid')->first;
  my @allowed_roles = qw(Admin Editor Owner);
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    debug "Update not allowed", route_parameters->get('id'), 'User:', $user->{username};
    status 401;
    return to_json({ error => 'Editing not allowed by user ' . $user->{username} });
  }
  # End auth check

  # Now handle the field update
  my $data = from_json(request->body);
  my %response = (success => 1);
  
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
      content  => trim($data->{value}),
      version  => $newVersion,
      editorid => $user->{'id'},
      created  => $t->datetime,
    });
    
    %response = (
      success => 1,
      content => trim($data->{value}),
      version => $newVersion,
      message => "Content updated successfully"
    );
    
  } elsif (
    # If title and slug are linked, we update both
    (route_parameters->get('field') eq 'title') &&
    ($article->{'slugtitle'} eq '1')
  ) {
    # Update title and slug if slugtitle is set to 1
    debug "Update title and slug";
    $article->update({
      title => trim($data->{value}),
      slug  => slugify(trim($data->{value}))
    });
    
    %response = (
      success => 1,
      slug    => $article->slug, 
      title   => $article->title,
      message => "Title and slug updated successfully"
    );
    
  } elsif (route_parameters->get('field') eq 'slug') {
    # Normalize slug using slugify
    debug "Update slug with normalized value";
    my $normalized_slug = slugify(trim($data->{value}));
    $article->update({ slug => $normalized_slug });
    
    %response = (
      success => 1,
      slug    => $article->slug,
      message => "Slug updated successfully"
    );
    
  } else {
    debug "Generic Update field ", route_parameters->get('field'), " with value ", $data->{value};
    $article->update({
      route_parameters->get('field') => trim($data->{value})
    });
    
    %response = (
      success => 1,
      route_parameters->get('field') => trim($data->{value}),
      message => "Field " . route_parameters->get('field') . " updated successfully"
    );
  }
  
  status 200;

  return to_json(\%response);
}

sub _article_delete {
  # start auth check
  my $user = session->read('user');
  unless ($user) {
    debug "No user", route_parameters->get('id');
    return template 'error' => {
      'title' => "No user error",
      'user' => 'unknown',
      'error_content' => "Need to be logged in to edit articles.",
    };
  }
  my $article = schema->resultset('Article')->find({ article_id => route_parameters->get('id') }, {});
  unless ($article) {
    debug "Article not found in _get_article_edit ", route_parameters->get('id');
    return template 'error' => {
      'title' => "Article not found",
      'user' => session->read('user'),
      'error_content' => "Article not found.",
    };
  }
  my $author_obj = $article->search_related('authorid')->first;
  # (1, 'Admin'),
  # (2, 'Editor'),
  # (3, 'Writer'),
  # (4, 'Visitor')
  my @allowed_roles = qw(Admin Editor Owner);
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    debug "Edit not allowed", route_parameters->get('id'), 'User:', $user->{username};
    return template 'error' => {
      'title' => $article->title . " error",
      'user' => session->read('user'),
      'error_content' => "Editing not allowed by user " . session->read('user'),
    };
  }
  # end auth check

  debug "Delete ", route_parameters->get('id');
  debug "Not implemented yet";
  return template 'error' => {
    'title' => $article->title . " error",
    'user' => session->read('user'),
    'error_content' => "Function nog niet geimplementeerd " . session->read('user'),
  };
  
}

# heeft auth check
sub _get_article_new {
  # start auth check
  my $user = session->read('user');
  unless ($user) {
    debug "No user", route_parameters->get('id');
    return template 'error' => {
      'title' => "No user error",
      'user' => 'unknown',
      'error_content' => "Need to be logged in to edit articles.",
    };
  }

  # Een nieuw artikel aanmaken, dus geen article ophalen, dus ook geen author_obj
  # (1, 'Admin'),
  # (2, 'Editor'),
  # (3, 'Writer'),
  # (4, 'Visitor')
  my @allowed_roles = qw(Admin Editor Writer);
  # Er is geen artikel dus ook geen author_obj
  my $author_obj = undef;
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    debug "New article not allowed", route_parameters->get('id'), 'User:', $user->{username};
    return template 'error' => {
      'title' => "New article error",
      'user' => session->read('user'),
      'error_content' => "Nieuw artikel niet toegestaan voor gebruiker " . session->read('user'),
    };
  }
  # end auth check

  # Passed auth check, show new article template
  my $categories = schema->resultset('Category')->search(
    {},
    { order_by => { '-asc' => 'title' } }
  );

  return template 'article/add' => {
    'title' => "New article",
    'user'  => session->read('user'),
    'categories' => $categories,
  }
}

# heeft auth check
sub _post_article_new {
  # start auth check
  my $user = session->read('user');
  unless ($user) {
    debug "No user", route_parameters->get('id');
    return template 'error' => {
      'title' => "No user error",
      'user' => 'unknown',
      'error_content' => "Need to be logged in to edit articles.",
    };
  }

  # Een nieuw artikel aanmaken, dus geen article ophalen, dus ook geen author_obj
  # (1, 'Admin'),
  # (2, 'Editor'),
  # (3, 'Writer'),
  # (4, 'Visitor')
  my @allowed_roles = qw(Admin Editor Writer);
  # Er is geen artikel dus ook geen author_obj
  my $author_obj = undef;
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    debug "Edit not allowed", route_parameters->get('id'), 'User:', $user->{username};
    return template 'error' => {
      'title' => "New article error",
      'user' => session->read('user'),
      'error_content' => "Nieuw artikel niet toegestaan voor gebruiker " . session->read('user'),
    };
  }
  # end auth check

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

  my $slug = unique_slug(length $slug_input ? $slug_input : $title);

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

# heeft auth check
sub _handle_keyword {
  # Start auth check
  # Gegevens komen vanuit JSON body
  my $data = from_json(request->body);
  debug Dumper $data;
  my $user = session->read('user');
  unless ($user) {
    status 401;
    return to_json({ error => 'Unauthorized' });
  } 

  # Ff wat gegevens ophalen van het artikel
  my $article = schema->resultset('Article')->find(
    {
      article_id => $data->{article_id}
    },{}
  );
  unless ($article) {
    debug "Article not found", route_parameters->get('article_id');
    status 404;
    return to_json({ error => 'Article not found' });
  }
  
  my $author_obj = $article->search_related('authorid')->first;
  my @allowed_roles = qw(Admin Editor Owner);
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    debug "Update not allowed", route_parameters->get('id'), 'User:', $user->{username};
    status 401;
    return to_json({ error => 'Editing not allowed by user ' . $user->{username} });
  }
  # End auth check

  # Now handle the keyword add/remove
  eval {
    if ($data->{checked}) {
      debug "Add keyword: $data->{keyword} to article: $data->{article_id}";
      my $keyword = schema->resultset('Keyword')->find_or_create({ title => $data->{keyword} });
      $article->add_to_keywords($keyword);
    } else {
      debug "Remove keyword: $data->{keyword} from article: $data->{article_id}";
      my $keyword = schema->resultset('Keyword')->find({ title => $data->{keyword} });
      if ($keyword) {
        $article->remove_from_keywords($keyword);
      }
    }
  };

  if ($@) {
    warning "DBIC error: $@";
    status 500;
    return to_json({ error => "Database error: $@" });
  } else {
    warning "Keyword handled successfully";
    status 200;
    return to_json({ result => "Ok"});
  }
}

# heeft auth check
sub _handle_category {
  # Start auth check
  # Gegevens komen vanuit JSON body
  my $data = from_json(request->body);
  debug Dumper $data;
  my $user = session->read('user');
  unless ($user) {
    status 401;
    return to_json({ error => 'Unauthorized' });
  } 

  # Ff wat gegevens ophalen van het artikel
  my $article = schema->resultset('Article')->find(
    {
      article_id => $data->{article_id}
    },{}
  );
  unless ($article) {
    debug "Article not found", route_parameters->get('article_id');
    status 404;
    return to_json({ error => 'Article not found' });
  }
  
  my $author_obj = $article->search_related('authorid')->first;
  my @allowed_roles = qw(Admin Editor Owner);
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    debug "Update not allowed", route_parameters->get('id'), 'User:', $user->{username};
    status 401;
    return to_json({ error => 'Editing not allowed by user ' . $user->{username} });
  }
  # End auth check

  # Now handle the keyword add/remove
  eval {
    if ($data->{checked}) {
      debug "Set category: $data->{category} for article: $data->{article_id}";
      my $category = schema->resultset('Category')->find_or_create({ title => $data->{category} });
      $article->update({ categoryid => $category->category_id });
    } else {
      # Single-select UI: unchecked events are ignored
      debug "Category change unchecked/ignored for article: $data->{article_id}";
    }
  };

  if ($@) {
    warning "DBIC error: $@";
    status 500;
    content_type 'application/json';
    return to_json({ error => "Database error: $@" });
  } else {
    status 200;
    content_type 'application/json';
    return to_json({ result => "Ok"});
  }
}

# geen auth check nodig
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

# geen auth check nodig
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


# Route definitions
prefix '/article' => sub {
  # Specific routes first (these must come before the generic :category/:slug route)
  get  '/keywords'           => \&_get_keywords;
  get  '/categories'         => \&_get_categories;
  get  '/new'                => \&_get_article_new;
  get  '/edit/:id'           => \&_get_article_edit;
  get  '/delete/:id'         => \&_article_delete;
  get  '/:category/:slug'    => \&_article;
  post '/add'                => \&_post_article_new;
  post '/update/:field/:id'  => \&_field_update;
  post '/keyword'            => \&_handle_keyword;
  post '/category'           => \&_handle_category;
};

42;