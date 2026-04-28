use utf8;
package MySite::Schema::Result::Page;


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("page");


__PACKAGE__->add_columns(
  "page_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "slug",
  { data_type => "text", is_nullable => 0 },
  "authorid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
  },
  "abstract",
  { data_type => "text", is_nullable => 0 },
  "meta_title",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "meta_description",
  { data_type => "text", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("page_id");
__PACKAGE__->add_unique_constraint("page_name_unique", ["name"]);
__PACKAGE__->add_unique_constraint("page_slug_unique", ["slug"]);


__PACKAGE__->belongs_to(
  "authorid",
  "MySite::Schema::Result::User",
  { user_id => "authorid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


__PACKAGE__->has_many(
  "page_contents",
  "MySite::Schema::Result::PageContent",
  { "foreign.pageid" => "self.page_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


sub url {
  my ($self) = shift;
  return(
    "/page/" .
    lc($self->slug)
  );
}

sub canonicalURL {
  my ($self, $base_url) = @_;
  $base_url ||= ''; # fallback als niet meegegeven
  $base_url =~ s{/$}{}; # trailing slash verwijderen
  return $base_url . $self->url;
}

1;
