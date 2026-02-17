use utf8;
package MySite::Schema::Result::Page;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MySite::Schema::Result::Page

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<page>

=cut

__PACKAGE__->table("page");

=head1 ACCESSORS

=head2 page_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 slug

  data_type: 'text'
  is_nullable: 0

=head2 authorid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1

=head2 abstract

  data_type: 'text'
  is_nullable: 0

=head2 meta_title

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 meta_description

  data_type: 'text'
  is_nullable: 1

=cut

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

=head1 PRIMARY KEY

=over 4

=item * L</page_id>

=back

=cut

__PACKAGE__->set_primary_key("page_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head2 C<slug_unique>

=over 4

=item * L</slug>

=back

=cut

__PACKAGE__->add_unique_constraint("slug_unique", ["slug"]);

=head1 RELATIONS

=head2 authorid

Type: belongs_to

Related object: L<MySite::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "authorid",
  "MySite::Schema::Result::User",
  { user_id => "authorid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 page_contents

Type: has_many

Related object: L<MySite::Schema::Result::PageContent>

=cut

__PACKAGE__->has_many(
  "page_contents",
  "MySite::Schema::Result::PageContent",
  { "foreign.pageid" => "self.page_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2026-02-15 13:09:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zyQ7a22/3EvYgpN93JAJIA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
