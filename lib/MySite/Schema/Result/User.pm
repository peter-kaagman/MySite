use utf8;
package MySite::Schema::Result::User;

use strict;
use warnings;
use base 'DBIx::Class::Core';


__PACKAGE__->table("user");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "source",
  { data_type => "text", is_nullable => 0 },
  "username",
  { data_type => "text", is_nullable => 0 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
  },
  "avatar",
  { data_type => "text", is_nullable => 1 },
  "roleid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", default_value => "unknown", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("user_id");
__PACKAGE__->add_unique_constraint("user_username_unique", ["username"]);

__PACKAGE__->has_many(
  "article_contents",
  "MySite::Schema::Result::ArticleContent",
  { "foreign.editorid" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "articles",
  "MySite::Schema::Result::Article",
  { "foreign.authorid" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "page_contents",
  "MySite::Schema::Result::PageContent",
  { "foreign.editorid" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "pages",
  "MySite::Schema::Result::Page",
  { "foreign.authorid" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "roleid",
  "MySite::Schema::Result::Role",
  { role_id => "roleid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


sub url {
  my ($self) = shift;
  return(
    "/user/" .
    $self->user_id 
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
#   $base_url =~ s{/$}{}; # trailing slash verwijderen
#   return $base_url . $self->url;
# }


1;
