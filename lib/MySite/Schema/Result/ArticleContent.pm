use utf8;
package MySite::Schema::Result::ArticleContent;


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("article_content");


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


__PACKAGE__->set_primary_key("article_content_id");


__PACKAGE__->belongs_to(
  "articleid",
  "MySite::Schema::Result::Article",
  { article_id => "articleid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "editorid",
  "MySite::Schema::Result::User",
  { user_id => "editorid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
