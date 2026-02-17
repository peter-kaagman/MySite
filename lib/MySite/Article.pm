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
use MySite::ErrorHandler qw(db_guard json_error template_error user_context);

# Route handlers

# geen auth check nodig
sub _article {
  # View article (public)
  my ($article_ok, $article) = db_guard(
    action => 'find article by slug',
    user => session->read('user'),
    code => sub {
      return schema->resultset('Article')->find(
        { slug => route_parameters->get('slug') },
        {}
      );
    }
  );
  
  unless ($article_ok) {
    return template_error(
      title => 'Article Error',
      error => 'Could not load article',
      status => 500
    );
  }
  
  unless ($article) {
    warning "Article not found for slug: ", route_parameters->get('slug');
    return template_error(
      title => 'Article not found',
      error => 'Article not found.',
      status => 404
    );
  }
  
  # Autheur voor authorisatie (to show edit and delete links)
  my $author = $article->search_related('authorid');
  debug "Article displayed: ", $article->article_id;
  my $content = $article->search_related(
    'article_contents',
    {},
    {
        order_by => {'-desc' => ['version']},
        rows => 1,
        page => 1

    }
  );
  
  # Handle skeleton articles with no content yet
  my $content_text = '';
  if (my $content_row = $content->first) {
    $content_text = $content_row->content;
  }
  
  # The base for in production should be loaded from config, but for development we can assume it's the same as the request base
  my $base_url = config->{'base_url'} || request->base;

  template 'article/article' => {
    'title' => $article->meta_title || $article->title,
    'meta_description' => $article->meta_description || '',
    'canonical_url' => $base_url . 'article/' . $article->categoryid->title . '/' . $article->slug,
    'user' => session->read('user'),
    'author' => $author->first,
    'article' => $article,
    'article_content' => $content_text,
    'render_markdown' => \&MySite::Utils::render_markdown,
    'show_content' => 1,
  }
}

# heeft auth check
sub _get_article_edit {
  # start auth check
  my $user = session->read('user');
  unless ($user) {
    warning "Unauthorized edit attempt on article: ", route_parameters->get('id');
    return template_error(
      title => "No user error",
      error => "Need to be logged in to edit articles.",
      status => 401
    );
  }
  my ($db_ok, $article) = db_guard(
    action => 'fetch article for edit',
    user => $user,
    code => sub {
      return schema->resultset('Article')->find({ article_id => route_parameters->get('id') }, {});
    }
  );
  unless ($db_ok) {
    return template_error(
      title => "Article Error",
      error => "Could not load article",
      status => 500
    );
  }
  unless ($article) {
    warning "Article not found for edit: ", route_parameters->get('id');
    return template_error(
      title => "Article not found",
      error => "Article not found.",
      status => 404
    );
  }
  my $author_obj = $article->search_related('authorid')->first;
  my @allowed_roles = qw(Admin Editor Owner);
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    warning "Edit not allowed", route_parameters->get('id'), 'User:', $user->{username};
    return template_error(
      title => $article->title . " error",
      error => "Editing not allowed by user " . $user->{username},
      status => 403
    );
  }
  # end auth check
  
  # Process article data for edit template
  my $content_count = $article->search_related('article_contents')->count;
  my @keywords = $article->keywords->all;
  my @keyword_data = map { { title => $_->title, id => $_->keyword_id } } @keywords;
  debug "Article keywords: ", scalar(@keyword_data);

  my $category_obj = $article->categoryid;
  my $category_data = { title => $category_obj->title, id => $category_obj->category_id };
  debug "Article category: ", $category_data->{title};

  my $content = $article->search_related(
    'article_contents',
    {},
    {
        order_by => {'-desc' => ['version']},
        rows => 1,
        page => 1

    }
  );

  debug "Opened article for editing: ", route_parameters->get('id');

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
    warning "Unauthorized field update attempt";
    return json_error(message => 'Unauthorized', status => 401);
  } 

  # Ff wat gegevens ophalen van het artikel
  my ($article_ok, $article) = db_guard(
    action => 'find article for update',
    user => $user,
    code => sub {
      return schema->resultset('Article')->find(
        { article_id => route_parameters->get('id') },
        {}
      );
    }
  );
  unless ($article_ok) {
    return json_error(message => 'Database error', status => 500);
  }
  unless ($article) {
    warning "Article not found for update: ", route_parameters->get('id');
    return json_error(message => 'Article not found', status => 404);
  }
  
  my $author_obj = $article->search_related('authorid')->first;
  my @allowed_roles = qw(Admin Editor Owner);
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    warning "Update not allowed", route_parameters->get('id'), 'User:', $user->{username};
    return json_error(
      message => 'Editing not allowed by user ' . $user->{username},
      status => 403
    );
  }
  # End auth check

  # Now handle the field update
  my $data;
  eval { $data = from_json(request->body); 1 } or do {
    warning "Invalid JSON in field update: ", $@;
    return json_error(message => 'Invalid JSON payload', status => 400);
  };
  my %response = (success => 1);
  my $field = route_parameters->get('field');
  my $trimmed_value = trim($data->{value} // '');

  if ($field eq 'content' || $field eq 'abstract') {
    unless (length $trimmed_value) {
      return json_error(message => 'Field cannot be empty', status => 400);
    }
  }
  
  # For content, we need to create a new version
  if ($field eq 'content') {
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
    
    # Handle skeleton articles with no content yet
    my $t = localtime;
    my $newVersion = 1;
    if (my $latest = $content->first) {
      $newVersion = $latest->version() + 1;
    }
    
    my ($content_ok) = db_guard(
      action => 'create article content version',
      user => $user,
      code => sub {
        $content->create({
          content  => $trimmed_value,
          version  => $newVersion,
          editorid => $user->{'id'},
          created  => $t->datetime,
        });
        return 1;
      }
    );
    unless ($content_ok) {
      return json_error(message => 'Database error', status => 500);
    }
    
    %response = (
      success => 1,
      content => $trimmed_value,
      version => $newVersion,
      message => "Content updated successfully"
    );
    
  } elsif (
    # If title and slug are linked, we update both
    ($field eq 'title') &&
    ($article->{'slugtitle'} eq '1')
  ) {
    # Update title and slug if slugtitle is set to 1
    debug "Update title and slug";
    my ($update_ok) = db_guard(
      action => 'update article title and slug',
      user => $user,
      code => sub {
        $article->update({
          title => $trimmed_value,
          slug  => slugify($trimmed_value)
        });
        return 1;
      }
    );
    unless ($update_ok) {
      return json_error(message => 'Database error', status => 500);
    }
    
    %response = (
      success => 1,
      slug    => $article->slug, 
      title   => $article->title,
      message => "Title and slug updated successfully"
    );
    
  } elsif ($field eq 'slug') {
    # Normalize slug using slugify
    debug "Update slug with normalized value";
    my $normalized_slug = slugify($trimmed_value);
    my ($update_ok) = db_guard(
      action => 'update article slug',
      user => $user,
      code => sub {
        $article->update({ slug => $normalized_slug });
        return 1;
      }
    );
    unless ($update_ok) {
      return json_error(message => 'Database error', status => 500);
    }
    
    %response = (
      success => 1,
      slug    => $article->slug,
      message => "Slug updated successfully"
    );
    
  } else {
    debug "Generic Update field ", $field, " with value ", $data->{value};
    my ($update_ok) = db_guard(
      action => 'update article field',
      user => $user,
      code => sub {
        $article->update({
          $field => $trimmed_value
        });
        return 1;
      }
    );
    unless ($update_ok) {
      return json_error(message => 'Database error', status => 500);
    }
    
    %response = (
      success => 1,
      $field => $trimmed_value,
      message => "Field " . $field . " updated successfully"
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
    warning "Unauthorized new article attempt";
    return template_error(
      title => "No user error",
      error => "Need to be logged in to create articles.",
      status => 401
    );
  }

  # Een nieuw artikel aanmaken, dus geen article ophalen, dus ook geen author_obj
  my @allowed_roles = qw(Admin Editor Writer);
  # Er is geen artikel dus ook geen author_obj
  my $author_obj = undef;
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    warning "New article not allowed for user: ", $user->{username};
    return template_error(
      title => "New article error",
      error => "Article creation not allowed for user " . $user->{username},
      status => 403
    );
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
    status 401;
    return to_json({ success => 0, error => 'Unauthorized' });
  }

  # Een nieuw artikel aanmaken, dus geen article ophalen, dus ook geen author_obj
  my @allowed_roles = qw(Admin Editor Writer);
  my $author_obj = undef;
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    warning "New article not allowed for user: ", $user->{username};
    return json_error(
      message => 'Nieuw artikel niet toegestaan voor dit account',
      status => 403
    );
  }
  # end auth check

  my $params;
  eval { $params = from_json(request->body); 1 } or do {
    warning "Invalid JSON in new article request: ", $@;
    return json_error(message => 'Ongeldige JSON payload', status => 400);
  };

  # Skeleton create: MINIMAL validation
  my $title      = trim($params->{title} // '');
  my $slug_input = trim($params->{slug} // '');
  my $slugtitle  = exists $params->{slugtitle} ? ($params->{slugtitle} ? 1 : 0) : 1;
  my $category_input = $params->{categoryid};
  my @keywords       = @{$params->{keywords} // []};

  # Validate required fields (title + category ONLY)
  unless (length $title) {
    status 400;
    return to_json({ success => 0, error => 'Titel is verplicht' });
  }

  unless ($category_input) {
    status 400;
    return to_json({ success => 0, error => 'Categorie is verplicht' });
  }

  # Validate category exists (accept ID or title)
  my $category;
  if (defined $category_input && $category_input =~ /^\d+$/) {
    $category = schema->resultset('Category')->find($category_input);
  } else {
    $category = schema->resultset('Category')->find({ title => $category_input });
  }
  unless ($category) {
    status 400;
    return to_json({ success => 0, error => 'Ongeldige categorie' });
  }

  # Generate slug
  my $slug = unique_slug(length $slug_input ? $slug_input : $title);

  # Create skeleton article (no content, empty abstract)
  my $article;
  my ($create_ok) = db_guard(
    action => 'create article skeleton',
    user => $user,
    code => sub {
      $article = schema->resultset('Article')->create({
        title      => $title,
        slug       => $slug,
        slugtitle  => $slugtitle,
        authorid   => $user->{id},
        categoryid => $category->category_id,
        abstract   => '', # Empty for now, will be filled in edit view
      });

      # Add keywords if provided
      foreach my $keyword_title (@keywords) {
        next unless length trim($keyword_title);
        my $keyword = schema->resultset('Keyword')->find_or_create(
          { title => trim($keyword_title) }
        );
        $article->add_to_keywords($keyword);
      }
      return 1;
    }
  );

  unless ($create_ok && $article) {
    return json_error(message => 'Artikel kon niet worden aangemaakt', status => 500);
  }

  debug "Created skeleton article: ", $article->article_id, " by user: ", $user->{username};
  status 201;
  return to_json({
    success    => 1,
    article_id => $article->article_id,
  });
}

# heeft auth check
sub _handle_keyword {
  # Start auth check
  # Gegevens komen vanuit JSON body
  my $data;
  eval { $data = from_json(request->body); 1 } or do {
    warning "Invalid JSON in keyword handler: ", $@;
    return json_error(message => 'Ongeldige JSON payload', status => 400);
  };
  debug Dumper $data;
  my $user = session->read('user');
  unless ($user) {
    warning "Unauthorized keyword update attempt";
    return json_error(message => 'Unauthorized', status => 401);
  } 

  # Ff wat gegevens ophalen van het artikel
  my ($article_ok, $article) = db_guard(
    action => 'find article for keyword update',
    user => $user,
    code => sub {
      return schema->resultset('Article')->find(
        { article_id => $data->{article_id} },
        {}
      );
    }
  );
  unless ($article_ok) {
    return json_error(message => 'Database error', status => 500);
  }
  unless ($article) {
    warning "Article not found for keyword update: ", $data->{article_id};
    return json_error(message => 'Article not found', status => 404);
  }
  
  my $author_obj = $article->search_related('authorid')->first;
  my @allowed_roles = qw(Admin Editor Owner);
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    warning "Keyword update not allowed", $data->{article_id}, 'User:', $user->{username};
    return json_error(
      message => 'Editing not allowed by user ' . $user->{username},
      status => 403
    );
  }
  # End auth check

  # Now handle the keyword add/remove
  my ($keyword_ok) = db_guard(
    action => 'update article keywords',
    user => $user,
    code => sub {
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
      return 1;
    }
  );

  debug "Keyword operation result for article: ", $data->{article_id};

  unless ($keyword_ok) {
    return json_error(message => 'Database error', status => 500);
  }

  content_type 'application/json';
  return to_json({ result => "Ok"});
}

# heeft auth check
sub _handle_category {
  # Start auth check
  # Gegevens komen vanuit JSON body
  my $data;
  eval { $data = from_json(request->body); 1 } or do {
    warning "Invalid JSON in category handler: ", $@;
    return json_error(message => 'Ongeldige JSON payload', status => 400);
  };
  debug Dumper $data;
  my $user = session->read('user');
  unless ($user) {
    warning "Unauthorized category update attempt";
    return json_error(message => 'Unauthorized', status => 401);
  } 

  # Ff wat gegevens ophalen van het artikel
  my ($article_ok, $article) = db_guard(
    action => 'find article for category update',
    user => $user,
    code => sub {
      return schema->resultset('Article')->find(
        { article_id => $data->{article_id} },
        {}
      );
    }
  );
  unless ($article_ok) {
    return json_error(message => 'Database error', status => 500);
  }
  unless ($article) {
    warning "Article not found for category update: ", $data->{article_id};
    return json_error(message => 'Article not found', status => 404);
  }
  
  my $author_obj = $article->search_related('authorid')->first;
  my @allowed_roles = qw(Admin Editor Owner);
  unless (user_can_edit_article($user, $author_obj, \@allowed_roles)) {
    warning "Category update not allowed", $data->{article_id}, 'User:', $user->{username};
    return json_error(
      message => 'Editing not allowed by user ' . $user->{username},
      status => 403
    );
  }
  # End auth check

  # Now handle the category change
  my ($category_ok) = db_guard(
    action => 'update article category',
    user => $user,
    code => sub {
      if ($data->{checked}) {
        debug "Set category: $data->{category} for article: $data->{article_id}";
        # Frontend always sends title now
        my $category = schema->resultset('Category')->find_or_create({ title => $data->{category} });
        $article->update({ categoryid => $category->category_id });
      } else {
        # Single-select UI: unchecked events are ignored
        debug "Category change unchecked/ignored for article: $data->{article_id}";
      }
      return 1;
    }
  );

  unless ($category_ok) {
    return json_error(message => 'Database error', status => 500);
  }
  
  content_type 'application/json';
  return to_json({ result => "Ok"});
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
  my @keyword_objects = map { { id => $_->keyword_id, title => $_->title } } $keywords->all;
  # debug "Keywords: ", join(', ', map { $_->{title} } @keyword_objects);
  content_type 'application/json';
  return to_json({ values => \@keyword_objects });
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
  my @category_objects = map { { id => $_->category_id, title => $_->title } } $categories->all;
  # debug "Categories: ", join(', ', map { $_->{title} } @category_objects);
  content_type 'application/json';
  return to_json({ values => \@category_objects });
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