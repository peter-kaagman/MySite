package MySite::Category;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;
use MySite::ErrorHandler qw(template_error);
use MySite::Utils qw(render_markdown datetime_to_human datetime_to_machine);
# Toon overzicht van artikelen in een categorie
sub category_overview {
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

my $breadcrumbs = [
    {
      name => 'Home',
      url  => "/",
    },
    {
      name => $category->title,
      url  => "/category/$slug",
    }
  ];



  template 'category/list' => {
    title    => $category->title,
    meta_description => $category->meta_description || 'Welkom op MySite, een persoonlijke website met technische artikelen.',
    category => $category,
    page_type => 'list',
    breadcrumbs => $breadcrumbs,
    list => \@articles,
    itemtype => 'TechArticle',
    datetime_to_human => \&datetime_to_human,
    # render_markdown => \&render_markdown,
  };
}


1;
