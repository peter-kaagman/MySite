use utf8;
package MySite::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MySite::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 source

  data_type: 'text'
  is_nullable: 0

=head2 username

  data_type: 'text'
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  is_nullable: 0

=head2 avatar

  data_type: 'text'
  is_nullable: 1

=head2 roleid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  default_value: 'unknown'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "source",
  { data_type => "text", is_nullable => 0 },
  "username",
  { data_type => "text", is_nullable => 0 },
  "created",
  { data_type => "timestamp", is_nullable => 0 },
  "avatar",
  { data_type => "text", is_nullable => 1 },
  "roleid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", default_value => "unknown", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<username_unique>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username_unique", ["username"]);

=head1 RELATIONS

=head2 article_contents

Type: has_many

Related object: L<MySite::Schema::Result::ArticleContent>

=cut

__PACKAGE__->has_many(
  "article_contents",
  "MySite::Schema::Result::ArticleContent",
  { "foreign.editorid" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 articles

Type: has_many

Related object: L<MySite::Schema::Result::Article>

=cut

__PACKAGE__->has_many(
  "articles",
  "MySite::Schema::Result::Article",
  { "foreign.authorid" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 page_contents

Type: has_many

Related object: L<MySite::Schema::Result::PageContent>

=cut

__PACKAGE__->has_many(
  "page_contents",
  "MySite::Schema::Result::PageContent",
  { "foreign.editorid" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pages

Type: has_many

Related object: L<MySite::Schema::Result::Page>

=cut

__PACKAGE__->has_many(
  "pages",
  "MySite::Schema::Result::Page",
  { "foreign.authorid" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 roleid

Type: belongs_to

Related object: L<MySite::Schema::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "roleid",
  "MySite::Schema::Result::Role",
  { role_id => "roleid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-11-28 21:17:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WG0DvASe4crp13WJxindFQ

sub returnURL {
  my ($self) = shift;
  return(
    "/user/" .
    $self->user_id 
  );
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
