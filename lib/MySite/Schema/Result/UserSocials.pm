use utf8;
package MySite::Schema::Result::UserSocials;

use strict;
use warnings;
use base 'DBIx::Class::Core';


__PACKAGE__->table("user_socials");
__PACKAGE__->add_columns(
  "social_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_nullable => 0 },
  "display_order",
  { data_type => "integer", is_nullable => 0, default_value => 1 },
  "social_name",
  { data_type => "text", is_nullable => 0 },
  "display_name",
  { data_type => "text", is_nullable => 0 },
  "social_url",
  { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("social_id");

__PACKAGE__->belongs_to(
    "user",
    "MySite::Schema::Result::User",
    { "foreign.user_id" => "self.user_id" },
    { cascade_copy => 0, cascade_delete => 0 },
);

1;
