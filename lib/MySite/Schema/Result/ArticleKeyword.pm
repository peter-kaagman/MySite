use utf8;
package MySite::Schema::Result::ArticleKeyword;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("article_keyword");
__PACKAGE__->add_columns(
  "articleid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "keywordid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);


__PACKAGE__->belongs_to(
  "articleid",
  "MySite::Schema::Result::Article",
  { article_id => "articleid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


__PACKAGE__->belongs_to(
  "keywordid",
  "MySite::Schema::Result::Keyword",
  { keyword_id => "keywordid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
