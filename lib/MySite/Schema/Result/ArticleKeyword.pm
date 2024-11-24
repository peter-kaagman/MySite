use utf8;
package MySite::Schema::Result::ArticleKeyword;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MySite::Schema::Result::ArticleKeyword

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<article_keyword>

=cut

__PACKAGE__->table("article_keyword");

=head1 ACCESSORS

=head2 articleid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 keywordid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "articleid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "keywordid",
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

=head2 keywordid

Type: belongs_to

Related object: L<MySite::Schema::Result::Keyword>

=cut

__PACKAGE__->belongs_to(
  "keywordid",
  "MySite::Schema::Result::Keyword",
  { keyword_id => "keywordid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-11-24 21:49:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ps0bmrhXxBvhnDog/UUrhQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
