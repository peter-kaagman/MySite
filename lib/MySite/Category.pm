package MySite::Category;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;
use MySite::ErrorHandler qw(template_error);
use MySite::Utils qw(render_markdown);

# Toon overzicht van artikelen in een categorie
sub _category_overview {
  my $slug = route_parameters->get('slug');
  my $category = schema->resultset('Category')->find({ slug => $slug });
  unless ($category) {
    return template_error(
      title  => 'Categorie niet gevonden',
      error  => 'Deze categorie bestaat niet.',
      status => 404
    );
  }
  my @articles = $category->articles->search({ deleted_at => undef }, { order_by => { '-desc' => 'created' } })->all;
  template 'category/list' => {
    title    => $category->title,
    category => $category,
    articles => \@articles,
    user     => session->read('user'),
    render_markdown => \&render_markdown,
  };
}


1;
