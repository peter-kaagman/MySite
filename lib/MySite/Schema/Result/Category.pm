use utf8;
package MySite::Schema::Result::Category;

use strict;
use warnings;
use FindBin;

use base 'DBIx::Class::Core';


__PACKAGE__->table("category");

__PACKAGE__->add_columns(
  "category_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "desc",
  { data_type => "text", is_nullable => 1 },
  "meta_title",
  { data_type => "text", is_nullable => 0 },
  "meta_description",
  { data_type => "text", is_nullable => 1 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
  },
  "slug",
  { 
    data_type => "text", 
    is_nullable => 1 
  },

);


__PACKAGE__->set_primary_key("category_id");
__PACKAGE__->add_unique_constraint("category_title_unique", ["title"]);
__PACKAGE__->add_unique_constraint("category_slug_unique", ["slug"]);


__PACKAGE__->has_many(
  "articles",
  "MySite::Schema::Result::Article",
  { "foreign.categoryid" => "self.category_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# sub slug {
#     my $self = shift;
#     # Generate slug from title, for example
#     return lc($self->title) =~ s/\s+/-/gr;
# }

sub url {
  my ($self) = shift;
  return(
    "/category/" .
    lc($self->slug)
  );
}

# Dit is niet correct:
# Een cononcial URL is altijd absoluut en moet dus
# niet afhankelijk zijn van een optionele base_url.
# Die base is niet impliciet aanwezig omdat er geen
# weer is of moet zijn van de Dancer2 context.
# sub canonicalURL {
#   my ($self, $base_url) = @_;
#   $base_url ||= ''; # fallback als niet meegegeven
#   $base_url =~ s/\/$//; # trailing slash verwijderen
#   return $base_url . $self->url;
# }

# sub logo_url {
#   my $self = shift;
#   return "/images/categories/" . $self->slug . ".png";
# }

sub logo {
  my $self = shift;
  my $base = '/images/categories/' . $self->slug . '.png';
  my $path = $FindBin::Bin . '/../public' . $base;
  return -e $path ? $base : "/images/categories/default.png";
}

1;