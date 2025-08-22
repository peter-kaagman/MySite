use utf8;
package MySite::Schema::Result::ArticleContent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MySite::Schema::Result::ArticleContent

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<article_content>

=cut

__PACKAGE__->table("article_content");

=head1 ACCESSORS

=head2 article_content_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 articleid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 version

  data_type: 'integer'
  is_nullable: 0

=head2 editorid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1

=head2 content

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "article_content_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "articleid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "version",
  { data_type => "integer", is_nullable => 0 },
  "editorid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
  },
  "content",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</article_content_id>

=back

=cut

__PACKAGE__->set_primary_key("article_content_id");

=head1 RELATIONS

=head2 articleid

Type: belongs_to

Related object: L<MySite::Schema::Result::Article>

=cut

__PACKAGE__->belongs_to(
  "articleid",
  "MySite::Schema::Result::Article",
  { article_id => "articleid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

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


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2025-08-14 12:07:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ngirFeJsVwKO95IkcnuNkg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
