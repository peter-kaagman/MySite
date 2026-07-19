use utf8;
package MySite::Schema::Result::Page;


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("page");
__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->add_columns(
  "page_id",           { data_type => "integer",   is_auto_increment => 1, is_nullable => 0 },
  "name",              { data_type => "text",      is_nullable => 0 },
  "slug",              { data_type => "text",      is_nullable => 0 },
  "authorid",          { data_type => "integer",   is_nullable => 0, is_foreign_key => 1 },
  "created",           { data_type => "timestamp", is_nullable   => 1, default_value => \"current_timestamp" },
  "abstract",          { data_type => "text",      is_nullable => 0 },
  "meta_title",        { data_type => "varchar",   is_nullable => 1, size => 255 },
  "meta_description",  { data_type => "text",      is_nullable => 1 },
  "include_in_sitemap",{ data_type => "integer",   is_nullable => 0, default_value => 1 },
  "allow_indexing",    { data_type => "integer",   is_nullable => 0, default_value => 1  },
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

sub latest_content {
    my ($self) = @_;

    return $self->{_latest_content} ||= $self->page_contents->search(
        {},
        {
            order_by => { -desc => 'version' },
            rows     => 1,
        }
    )->first;
}

sub date_modified {
    my ($self) = @_;

    my $content = $self->latest_content;

    return $content
    ? $content->created
    : $self->created;
}

1;
