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

=head2 desc

  data_type: 'text'
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "category_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "desc",
  { data_type => "text", is_nullable => 1 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
  },
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

=head2 articles

Type: has_many

Related object: L<MySite::Schema::Result::Article>

=cut

__PACKAGE__->has_many(
  "articles",
  "MySite::Schema::Result::Article",
  { "foreign.categoryid" => "self.category_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2025-08-14 12:07:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6iyjqQJ7tfAl6e+5htc3Iw

sub slug {
    my $self = shift;
    # Generate slug from title, for example
    return lc($self->title) =~ s/\s+/-/gr;
}

sub returnURL {
  my ($self) = shift;
  return(
    "/category/" .
    lc($self->title) =~ s/\s+/-/gr 
  );
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
