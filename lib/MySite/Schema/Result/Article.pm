use utf8;
package MySite::Schema::Result::Article;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MySite::Schema::Result::Article

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<article>

=cut

__PACKAGE__->table("article");

=head1 ACCESSORS

=head2 article_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 slug

  data_type: 'text'
  is_nullable: 0

=head2 authorid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 categoryid

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  is_nullable: 0

=head2 abstract

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "article_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "slug",
  { data_type => "text", is_nullable => 0 },
  "authorid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "categoryid",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "created",
  { data_type => "timestamp", is_nullable => 0 },
  "abstract",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</article_id>

=back

=cut

__PACKAGE__->set_primary_key("article_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<slug_unique>

=over 4

=item * L</slug>

=back

=cut

__PACKAGE__->add_unique_constraint("slug_unique", ["slug"]);

=head2 C<title_unique>

=over 4

=item * L</title>

=back

=cut

__PACKAGE__->add_unique_constraint("title_unique", ["title"]);

=head1 RELATIONS

=head2 article_contents

Type: has_many

Related object: L<MySite::Schema::Result::ArticleContent>

=cut

__PACKAGE__->has_many(
  "article_contents",
  "MySite::Schema::Result::ArticleContent",
  { "foreign.articleid" => "self.article_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 article_keywords

Type: has_many

Related object: L<MySite::Schema::Result::ArticleKeyword>

=cut

__PACKAGE__->has_many(
  "article_keywords",
  "MySite::Schema::Result::ArticleKeyword",
  { "foreign.articleid" => "self.article_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-11-24 21:49:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:W2A6ZsKTS+SVnjHkc1RWnw

__PACKAGE__->many_to_many(
   
  'keywords'            # Naam van de many_2_many relatie
    => 
    'article_keywords', # Relatie naar de koppeltabel
    'keywordid'         # Relatie in de koppeltabel naar doeltabel
);
# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
