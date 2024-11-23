use utf8;
package MySite::Schema::Result::Category;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MySite::Schema::Result::Category

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<category>

=cut

__PACKAGE__->table("category");

=head1 ACCESSORS

=head2 category_id

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
  "category_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "created",
  { data_type => "timestamp", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</category_id>

=back

=cut

__PACKAGE__->set_primary_key("category_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<title_unique>

=over 4

=item * L</title>

=back

=cut

__PACKAGE__->add_unique_constraint("title_unique", ["title"]);

=head1 RELATIONS

=head2 article_categories

Type: has_many

Related object: L<MySite::Schema::Result::ArticleCategory>

=cut

__PACKAGE__->has_many(
  "article_categories",
  "MySite::Schema::Result::ArticleCategory",
  { "foreign.categoryid" => "self.category_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-11-20 11:15:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WnEgndZ6DkyAiI4cRF1EbA

__PACKAGE__->many_to_many(
  'articles'             # Name of the relation
  => 
  'article_categories', # The local relation to the couple table
  'articleid'           # The relation in the couple table to the target
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
