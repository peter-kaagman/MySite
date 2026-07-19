use utf8;
package MySite::Schema::Result::Article;


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("article");
__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->add_columns(
  "article_id",       { data_type => "integer",   is_nullable => 0, is_auto_increment => 1 },
  "title",            { data_type => "text",      is_nullable => 0 },
  "slug",             { data_type => "text",      is_nullable => 0 },
  "slugtitle",        { data_type => "integer",   is_nullable => 1, default_value => 1 },
  "authorid",         { data_type => "integer",   is_nullable => 0, is_foreign_key => 1 },
  "categoryid",       { data_type => "integer",   is_nullable => 0, is_foreign_key => 1 },
  "created",          { data_type => "timestamp", is_nullable => 1, default_value => \"current_timestamp"},
  "published",        { data_type => "timestamp", is_nullable => 1 },
  "abstract",         { data_type => "text",      is_nullable => 0 },
  "meta_title",       { data_type => "varchar",   is_nullable => 1, size => 255 },
  "meta_description", { data_type => "text",      is_nullable => 1 },
  "deleted_at",       { data_type => "datetime",  is_nullable => 1 },
);


__PACKAGE__->set_primary_key("article_id");
__PACKAGE__->add_unique_constraint("article_slug_unique", ["slug"]);
__PACKAGE__->add_unique_constraint("article_title_unique", ["title"]);


__PACKAGE__->has_many(
  "article_contents",
  "MySite::Schema::Result::ArticleContent",
  { "foreign.articleid" => "self.article_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->has_many(
  "article_keywords",
  "MySite::Schema::Result::ArticleKeyword",
  { "foreign.articleid" => "self.article_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->belongs_to(
  "authorid",
  "MySite::Schema::Result::User",
  { user_id => "authorid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


__PACKAGE__->belongs_to(
  "categoryid",
  "MySite::Schema::Result::Category",
  { category_id => "categoryid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->many_to_many(
   
  'keywords'            # Naam van de many_2_many relatie
    => 
    'article_keywords', # Relatie naar de koppeltabel
    'keywordid'         # Relatie in de koppeltabel naar doeltabel
);


sub url {
  my ($self) = shift;
  return(
    "/article/" .
    # $self->categoryid->slug .
    # "/" .
    $self->slug 
  );
}

# Dit is niet correct:
# Een cononcial URL is altijd absoluut en moet dus
# niet afhankelijk zijn van een optionele base_url.
# Die base is niet impliciet aanwezig omdat er geen
# weer is of moet zijn van de Dancer2 context.
# sub canonicalURL {
#   my ($self, $base_url) = @_;
#   $base_url ||= ''; # fallback als niet meegegeven
#   $base_url =~ s{/$}{}; # trailing slash verwijderen
#   return config{'base_url'} . $self->url;
# }

sub is_owned_by {
  my ($self, $user) = @_;
  return 0 unless $user && $user->{username};
  my $author = $self->search_related('authorid')->first;
  return 0 unless $author;
  return $author->username eq $user->{username} ? 1 : 0;
}

# Slug validation
sub insert {
  my $self = shift;
  $self->_validate_slug();
  return $self->next::method(@_);
}

sub update {
  my $self = shift;
  $self->_validate_slug();
  return $self->next::method(@_);
}

sub _validate_slug {
  my $self = shift;
  my $slug = $self->slug or return;
  
  # Check voor spaties
  if ($slug =~ /\s/) {
    die "Slug cannot contain spaces: '$slug'";
  }
  
  # Check voor lowercase
  if ($slug ne lc($slug)) {
    die "Slug must be lowercase: '$slug'";
  }
  
  # Check voor alleen toegestane karakters (lowercase letters, numbers, hyphens, underscores)
  if ($slug =~ /[^a-z0-9_-]/) {
    die "Slug can only contain lowercase letters, numbers, hyphens and underscores: '$slug'";
  }
  return 1;
}

sub latest_content {
    my ($self) = @_;

    return $self->{_latest_content} ||= $self->article_contents->search(
        {},
        {
            order_by => { -desc => 'version' },
            rows     => 1,
        }
    )->first;
}

sub date_modified {
    my ($self) = @_;

    my $content = $self->latest_content;

    return $content
    ? $content->created
    : $self->created;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
