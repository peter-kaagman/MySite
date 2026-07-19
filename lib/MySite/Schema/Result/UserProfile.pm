use utf8;
package MySite::Schema::Result::UserProfile;

use strict;
use warnings;
use base 'DBIx::Class::Core';


__PACKAGE__->table("user_profile");
__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->add_columns(
  "user_id",          { data_type => "integer", is_nullable => 0 },
  "public_profile",   { data_type => "integer", is_nullable => 0, default_value => 0 },
  "display_name",     { data_type => "text",    is_nullable => 1 },
  "tagline",          { data_type => "text",    is_nullable => 1 },
  "email",            { data_type => "text",    is_nullable => 0 },
  "bio",              { data_type => "text",    is_nullable => 1 },
  "meta_description", { data_type => "text",    is_nullable => 1 },
  "created",          { data_type => "timestamp", is_nullable => 1, default_value => \"current_timestamp" },
  "updated",          { data_type => "timestamp", is_nullable => 1, default_value => \"current_timestamp" },
);

__PACKAGE__->set_primary_key("user_id");

__PACKAGE__->belongs_to(
  "user",
  "MySite::Schema::Result::User",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
