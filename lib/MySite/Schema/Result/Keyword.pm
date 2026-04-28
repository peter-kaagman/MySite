use utf8;
package MySite::Schema::Result::Keyword;


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("keyword");


__PACKAGE__->add_columns(
  "keyword_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
  },
  "slug",
  { 
    data_type => "text", 
    is_nullable => 1 
  },

);


__PACKAGE__->set_primary_key("keyword_id");
__PACKAGE__->add_unique_constraint("keyword_title_unique", ["title"]);
__PACKAGE__->add_unique_constraint("keyword_slug_unique", ["slug"]);


__PACKAGE__->has_many(
  "article_keywords",
  "MySite::Schema::Result::ArticleKeyword",
  { "foreign.keywordid" => "self.keyword_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many(
  'articles'             # Name of the relation
  => 
  'article_keywords', # The local relation to the couple table
  'articleid'           # The relation in the couple table to the target
);

# sub slug {
#     my $self = shift;
#     # Generate slug from title, for example
#     return lc($self->title) =~ s/\s+/-/gr;
# }

sub url {
  my ($self) = shift;
  return(
    "/keyword/" .
    lc($self->slug)
  );
}

sub canonicalURL {
  my ($self, $base_url) = @_;
  $base_url ||= ''; # fallback als niet meegegeven
  $base_url =~ s{/$}{}; # trailing slash verwijderen
  return $base_url . $self->url;
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
