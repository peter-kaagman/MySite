use utf8;
package MySite::Schema::Result::Role;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MySite::Schema::Result::Role

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<role>

=cut

__PACKAGE__->table("role");

=head1 ACCESSORS

=head2 role_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "role_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</role_id>

=back

=cut

__PACKAGE__->set_primary_key("role_id");

=head1 RELATIONS

=head2 users

Type: has_many

Related object: L<MySite::Schema::Result::User>

=cut

__PACKAGE__->has_many(
  "users",
  "MySite::Schema::Result::User",
  { "foreign.roleid" => "self.role_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-11-20 11:15:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tmXbcVP4I1XkihpjERDqbA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
