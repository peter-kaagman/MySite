package MySite::Index;

use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use Template;
use FindBin;
use MySite::Utils qw(render_markdown jsonld_base normalize_ts_machine format_date_human);
use MySite::ErrorHandler qw(db_guard template_error);

# Health check endpoint for Docker
sub _health{
  content_type 'application/json';
  return to_json({ 
    status => 'ok', 
    version => $MySite::VERSION,
    timestamp => time()
  });
};

# Sitemap route
sub _sitemap {
  my @urls;
  my $home_lastmod;


  # Voeg alle artikelen toe
  my $articles = schema->resultset('Article')->search({ deleted_at => undef }, { order_by => { '-desc' => ['created'] } });
  
  while (my $article = $articles->next) {
    my $lastmod = normalize_ts_machine($article->date_modified);

    $home_lastmod //= $lastmod;

    push @urls, {
        path => $article->url,
        lastmod => $lastmod,
    };
  }


  unshift @urls, { path => "/", lastmod => $home_lastmod };

  # Voeg alle pages toe
  my $pages = schema->resultset('Page')->search(
    { include_in_sitemap => 1 },
    { order_by => { '-desc' => ['created'] } }
  );
  while (my $page = $pages->next) {
    push @urls, {
      path => $page->url,
      lastmod => normalize_ts_machine($page->date_modified),
      publication => normalize_ts_machine($page->created),
    };
  }

  # Voeg de categoriepagina's toe, als ze tenminste één artikel bevatten
  my $categories = schema->resultset('Category')->search(
    {},
    { order_by => { '-desc' => ['created'] } }
  );

  while (my $category = $categories->next) {
    my $latest_article = $category->articles->search(
      {},
      {
        order_by => { '-desc' => ['created'] },
        rows     => 1,
      }
    )->first;
    next unless $latest_article;
    push @urls, {
      path         => $category->url,
      lastmod     => normalize_ts_machine($latest_article->date_modified),
      publication => normalize_ts_machine($latest_article->created),
    };
  }

  content_type 'application/xml';
  return template 'sitemap.tt', {
      urls => \@urls,
  }, { layout => undef };

};

sub _index {
    # debug "Rendering landing page";
    my ($db_ok, $page) = db_guard(
        action => 'fetch landing page',
        user   => session->read('user'),
        code   => sub {
            return schema->resultset('Page')->find({ slug => 'index' });
        }
    );
    # debug "Database OK: $db_ok, Page found: " . ($page ? 'yes' : 'no');

    unless ($db_ok) {
        return template_error(
            title  => 'Database Error',
            error  => 'Could not load landing page',
            status => 500
        );
    }

    unless ($page) {
        debug "Landing page not found, returning 404";
        status 404;
        return template 'error.tt', { message => "Landingspagina niet gevonden" };
    }

    my $content = schema->resultset('PageContent')->search({
        pageid    => $page->page_id,
        published => { '!=', undef },
    }, {
        order_by => { -desc => 'published' },
        rows     => 1,
    })->first;

    my @categories = schema->resultset('Category')->search(
        {
            'articles.article_id' => { '!=' => undef },
        },
        {
            join     => 'articles',
            group_by => 'me.category_id',
            order_by => { -desc => 'me.title' },
        }
    )->all;

  my $breadcrumbs = [
    {
      name => 'Home',
      url  => "/",
    }
  ];

  my $rs = schema->resultset('Page');
  # warn "Storage: " . ref($rs->result_source->schema->storage);

  template 'page.tt' => {
      'title'            => $page->meta_title,
      'meta_description' => $page->meta_description || 'Welkom op MySite, een persoonlijke website met technische artikelen.',
      'content'          => $content,
      'page_type'        => 'list',
      'breadcrumbs'      => $breadcrumbs,
      'list'             => \@categories,
      'itemtype'          => 'CollectionPage',
      'render_markdown'  => \&MySite::Utils::render_markdown,
      'allow_indexing' => 1,
  };
}

sub _prometheus_metrics {
  content_type 'text/plain; version=0.0.4';
  return $MySite::obs->prometheus_export();
}
42;