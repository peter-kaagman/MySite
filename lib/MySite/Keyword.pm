package MySite::Keyword;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;
use MySite::ErrorHandler qw(template_error);

# Toon overzicht van artikelen bij een keyword
sub _keyword_overview {
  my $slug = route_parameters->get('slug');
  my $keyword = schema->resultset('Keyword')->find({ slug => $slug });
  unless ($keyword) {
    return template_error(
      title  => 'Keyword niet gevonden',
      error  => 'Dit keyword bestaat niet.',
      status => 404
    );
  }


  # Haal alle artikelen op die aan dit keyword gekoppeld zijn en niet gedelete zijn
  my @articles = $keyword->articles->search(
    {
      deleted_at => undef
    },
    {
      order_by => { '-desc' => 'created' }
    }
  )->all;


  my $breadcrumbs = [
    {
      name => 'Home',
      url  => "/",
    },
    {
      name => $keyword->title,
      url  => "/keyword/$slug",
    }
  ];


  template 'keyword/list' => {
    title    => $keyword->title,
    keyword  => $keyword,
    list => \@articles,
    page_type => 'list',
    itemtype => 'TechArticle',
    breadcrumbs => $breadcrumbs,
  };
}


1;
