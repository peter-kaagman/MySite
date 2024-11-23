use utf8;
package MySite::Schema::Result::PageContent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MySite::Schema::Result::PageContent

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<page_content>

=cut

__PACKAGE__->table("page_content");

=head1 ACCESSORS

=head2 page_content_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 pageid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 version

  data_type: 'integer'
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  is_nullable: 0

=head2 published

  data_type: 'timestamp'
  is_nullable: 1

=head2 editorid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 content

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "page_content_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "pageid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "version",
  { data_type => "integer", is_nullable => 0 },
  "created",
  { data_type => "timestamp", is_nullable => 0 },
  "published",
  { data_type => "timestamp", is_nullable => 1 },
  "editorid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</page_content_id>

=back

=cut

__PACKAGE__->set_primary_key("page_content_id");

=head1 RELATIONS

=head2 editorid

Type: belongs_to

Related object: L<MySite::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "editorid",
  "MySite::Schema::Result::User",
  { user_id => "editorid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 pageid

Type: belongs_to

Related object: L<MySite::Schema::Result::Page>

=cut

__PACKAGE__->belongs_to(
  "pageid",
  "MySite::Schema::Result::Page",
  { page_id => "pageid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-11-20 11:15:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NUc1HQvmQoUjtP6gVhD8sQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
