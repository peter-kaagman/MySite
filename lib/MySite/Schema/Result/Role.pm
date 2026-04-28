use utf8;
package MySite::Schema::Result::Role;

use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("role");


__PACKAGE__->add_columns(
  "role_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("role_id");


__PACKAGE__->has_many(
  "users",
  "MySite::Schema::Result::User",
  { "foreign.roleid" => "self.role_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


1;
