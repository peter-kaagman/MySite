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
  my @articles = map { $_->articleid }
    $keyword->article_keywords->search(
      { 'articleid.deleted_at' => undef },
      { prefetch => 'articleid', order_by => { '-desc' => 'articleid.created' } }
    )->all;
  template 'keyword/list' => {
    title    => $keyword->title,
    keyword  => $keyword,
    articles => \@articles,
  };
}


1;
