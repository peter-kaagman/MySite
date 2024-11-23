use utf8;
package MySite::Schema::Result::ArticleCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MySite::Schema::Result::ArticleCategory

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<article_category>

=cut

__PACKAGE__->table("article_category");

=head1 ACCESSORS

=head2 articleid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 categoryid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "articleid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "categoryid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

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

=head2 categoryid

Type: belongs_to

Related object: L<MySite::Schema::Result::Category>

=cut

__PACKAGE__->belongs_to(
  "categoryid",
  "MySite::Schema::Result::Category",
  { category_id => "categoryid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-11-20 11:15:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:66dwDJc8pvlGXHSWBwGqzg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
