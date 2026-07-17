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
  {data_type => "timestamp", is_nullable => 1, default_value => \"current_timestamp" },
  "slug",
  { data_type => "text", is_nullable => 0, default_value => "" },
  "is_trusted",
  { data_type => "integer", is_nullable => 0, default_value => 0 },
  "is_banned",
  { data_type => "integer", is_nullable => 0, default_value => 0 },
  "roleid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", default_value => "unknown", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("user_id");
__PACKAGE__->add_unique_constraint("user_username_unique", ["username"]);
__PACKAGE__->add_unique_constraint("user_slug_unique", ["slug"]);

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

__PACKAGE__->might_have(
  "user_profile",
  "MySite::Schema::Result::UserProfile",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "user_socials",
  "MySite::Schema::Result::UserSocials",
  { "foreign.user_id" => "self.user_id" },
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
    "/profile/" .
    $self->slug 
  );
}

sub generate_slug {
    my ($class, $schema, $username) = @_;

    my $slug = lc($username);

    $slug =~ s/\@.*$//;
    $slug =~ s/[^a-z0-9]+/-/g;
    $slug =~ s/^-+//;
    $slug =~ s/-+$//;

    my $base = $slug;
    my $n    = 1;

    while (
        $schema->resultset('User')->find(
            { slug => $slug }
        )
    ) {
        $n++;
        $slug = "$base-$n";
    }

    return $slug;
}

1;
