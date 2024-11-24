use utf8;
package MySite::Schema::Result::Keyword;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MySite::Schema::Result::Keyword

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<keyword>

=cut

__PACKAGE__->table("keyword");

=head1 ACCESSORS

=head2 keyword_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "keyword_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "created",
  { data_type => "timestamp", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</keyword_id>

=back

=cut

__PACKAGE__->set_primary_key("keyword_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<title_unique>

=over 4

=item * L</title>

=back

=cut

__PACKAGE__->add_unique_constraint("title_unique", ["title"]);

=head1 RELATIONS

=head2 article_keywords

Type: has_many

Related object: L<MySite::Schema::Result::ArticleKeyword>

=cut

__PACKAGE__->has_many(
  "article_keywords",
  "MySite::Schema::Result::ArticleKeyword",
  { "foreign.keywordid" => "self.keyword_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-11-24 21:49:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:K69+onzrvpggipU83luJPQ
__PACKAGE__->many_to_many(
  'articles'             # Name of the relation
  => 
  'article_keywords', # The local relation to the couple table
  'articleid'           # The relation in the couple table to the target
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
