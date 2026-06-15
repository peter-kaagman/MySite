package MySite::Index;

use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use Template;
use FindBin;
use MySite::Utils qw(render_markdown);
use MySite::ErrorHandler qw(db_guard template_error);

sub _normalize_ts {
  my ($value) = @_;
  return '' unless defined $value;

  if (ref $value) {
    return $value->strftime('%Y-%m-%d %H:%M:%S') if $value->can('strftime');
    if ($value->can('ymd')) {
      my $date = $value->ymd;
      my $time = $value->can('hms') ? $value->hms : '00:00:00';
      return "$date $time";
    }
  }

  my $str = "$value";
  if ($str =~ /^(\d{4}-\d{2}-\d{2})(?:[ T](\d{2}:\d{2}:\d{2}))?/) {
    return $1 . ' ' . ($2 // '00:00:00');
  }

  return $str;
}

# # Wordt dit uberhaupt gebruikt? Zo ja, dan zou het eigenlijk moeten sorteren op de laatste content update, niet op article.created.
# sub _article_sort_ts {
#   my ($article) = @_;
#   my $latest_content = $article->article_contents->search(
#     {},
#     { order_by => { '-desc' => ['created'] }, rows => 1 }
#   )->first;

#   my $value = $latest_content
#     ? $latest_content->created
#     : ($article->published // $article->created);

#   return _normalize_ts($value);
# }


sub _index {
    my ($db_ok, $articles) = db_guard(
      action => 'fetch articles for homepage',
      user => session->read('user'),
      code => sub {
        return schema->resultset('Article')->search(
          { deleted_at => undef }
        );
      }
    );
    
    unless ($db_ok) {
      return template_error(
        title => 'Database Error',
        error => 'Could not load articles',
        status => 500
      );
    }

    # Sorteer uitsluitend op article.created (nieuwste eerst).
    my @articles_sorted = sort {
      _normalize_ts($b->created) cmp _normalize_ts($a->created)
    } $articles->all;

    debug "Fetched ", scalar(@articles_sorted), " articles for homepage";

    my $index = 1;
    my @json_ld_list;
    foreach my $article (@articles_sorted) {
      push @json_ld_list, {
        '@type' => "ListItem",
        'position' => $index++,
        'url' => $article->canonicalURL(config->{base_url} // request->base),
        'name' => $article->title,
      };
    }
    my $json_ld = encode_json ({
      '@context' => "https://schema.org",
      '@type' => "WebPage",
      'name' => "MySite - Artikelen",
      'url' => "https://mysite.prjv.nl/",
      'description' => "Overzicht van artikelen",
      'inLanguage' => "nl",
      'mainEntity' => {
        '@type' => "ItemList",
        'itemListElement' => \@json_ld_list,
      }

    });

    template 'article/list' => {
        'title' => 'MySite',
        'canonical_url' => (config->{'base_url'} || request->base),
        'json_ld' => $json_ld,
        'meta_description' => 'Welkom op MySite, een persoonlijke website met technische artikelen.',
        'user' => session->read('user'),
        'articles' => \@articles_sorted,
        'render_markdown' => \&MySite::Utils::render_markdown,
    };
}


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

get '/' => \&_index;


get '/sitemap.xml' => \&_sitemap;

42;