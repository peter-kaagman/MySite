package MySite::Index;

use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use Template;
use FindBin;
use MySite::Utils qw(render_markdown);
use MySite::ErrorHandler qw(db_guard template_error);


# Sitemap route
sub _sitemap {
  my $schema = schema;
  my $base_url = config->{base_url} // request->base;
  $base_url .= '/' unless $base_url =~ m{/$};
  my @urls;
  my $home_lastmod;
  # Voeg alle artikelen toe
  my $articles = $schema->resultset('Article')->search({ deleted_at => undef }, { order_by => { '-desc' => ['created'] } });
  while (my $article = $articles->next) {
    # Zoek de hoogste versie van ArticleContent voor dit artikel
    my $content = $article->article_contents->search({}, { order_by => { '-desc' => ['version'] }, rows => 1 })->first;
    my $lastmod = $content ? $content->created : ($article->published // $article->created);
    if ($lastmod) {
      if (ref $lastmod && $lastmod->can('ymd')) {
        $lastmod = $lastmod->ymd;
      } elsif ($lastmod =~ /^(\d{4}-\d{2}-\d{2})/) {
        $lastmod = $1;
      }
    }
    # Artikelresultset is sorted newest-first; first entry is homepage lastmod.
    $home_lastmod //= $lastmod;
    push @urls, {
      loc => $article->canonicalURL($base_url),
      lastmod => $lastmod,
      publication => ($article->created ? (ref $article->created && $article->created->can('ymd') ? $article->created->ymd : $article->created) : undef),
    };
  }

  unshift @urls, { loc => $base_url, lastmod => $home_lastmod };

  # Voeg alle pages toe
  my $pages = $schema->resultset('Page')->search(
    { slug => { '!=' => 'login' } },
    { order_by => { '-desc' => ['created'] } }
  );
  while (my $page = $pages->next) {
    # Zoek de hoogste versie van PageContent voor deze page
    my $content = $page->page_contents->search({}, { order_by => { '-desc' => ['version'] }, rows => 1 })->first;
    my $lastmod = $content ? ($content->published // $content->created) : $page->created;
    if ($lastmod) {
      if (ref $lastmod && $lastmod->can('ymd')) {
        $lastmod = $lastmod->ymd;
      } elsif ($lastmod =~ /^(\d{4}-\d{2}-\d{2})/) {
        $lastmod = $1;
      }
    }
    push @urls, {
      loc => $page->canonicalURL($base_url),
      lastmod => $lastmod,
      # publication => ($page->created ? (ref $page->created && $page->created->can('ymd') ? $page->created->ymd : $page->created) : undef),
    };
  }
  content_type 'application/xml';
  my $xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
  $xml .= "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n";
  for my $url (@urls) {
    $xml .= "  <url>\n";
    $xml .= "    <loc>" . $url->{loc} . "</loc>\n";
    $xml .= "    <lastmod>" . $url->{lastmod} . "</lastmod>\n" if $url->{lastmod};
    # $xml .= "    <publication_date>" . $url->{publication} . "</publication_date>\n" if $url->{publication};
    $xml .= "  </url>\n";
  }
  $xml .= "</urlset>\n";
  return $xml;
};

sub _index {
    my ($db_ok, $page) = db_guard(
        action => 'fetch landing page',
        user   => session->read('user'),
        code   => sub {
            return schema->resultset('Page')->find({ slug => 'index' });
        }
    );

    unless ($db_ok) {
        return template_error(
            title  => 'Database Error',
            error  => 'Could not load landing page',
            status => 500
        );
    }

    unless ($page) {
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

    template 'page.tt' => {
        'title'            => $page->meta_title || $page->name,
        'canonical_url'    => (config->{'base_url'} || request->base),
        'meta_description' => $page->meta_description || 'Welkom op MySite, een persoonlijke website met technische artikelen.',
        'user'             => session->read('user'),
        'content'          => $content,
        'render_markdown'  => \&MySite::Utils::render_markdown,
    };
}

get '/' => \&_index;

get '/sitemap.xml' => \&_sitemap;

42;