package MySite::Utils;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;
use Text::Markdown::Hoedown qw(markdown HOEDOWN_EXT_FENCED_CODE HOEDOWN_EXT_TABLES HOEDOWN_EXT_AUTOLINK HOEDOWN_EXT_STRIKETHROUGH HOEDOWN_EXT_FOOTNOTES HOEDOWN_EXT_HIGHLIGHT HOEDOWN_EXT_SUPERSCRIPT);
use Exporter 'import';
# # use parent 'Exporter::Tiny';

our @EXPORT_OK = qw(render_markdown require_user_logged_in user_can_edit_article slugify unique_slug);
# our %EXPORT_TAGS = (
#   all => \@EXPORT_OK,
# );

# Use a Markdown rendering library to convert Markdown to HTML
sub render_markdown {
  my ($text) = @_;
  my $ext = HOEDOWN_EXT_FENCED_CODE
          | HOEDOWN_EXT_TABLES
          | HOEDOWN_EXT_AUTOLINK
          | HOEDOWN_EXT_STRIKETHROUGH
          | HOEDOWN_EXT_FOOTNOTES
          | HOEDOWN_EXT_HIGHLIGHT
          | HOEDOWN_EXT_SUPERSCRIPT;
  my $html = markdown($text, extensions => $ext);
  return $html;
}

# Slug helper: normalize text to URL-safe slug
sub slugify {
  my ($text) = @_;
  $text //= '';
  $text = lc $text;
  $text =~ s/[^a-z0-9]+/_/g;
  $text =~ s/^_+|_+$//g;
  $text = 'artikel' unless length $text;
  return $text;
}

# Generate a unique slug based on base text
sub unique_slug {
  my ($base_text) = @_;
  my $base = slugify($base_text);
  my $slug = $base;
  my $counter = 2;

  while (schema->resultset('Article')->find({ slug => $slug })) {
    $slug = $base . '_' . $counter;
    $counter++;
  }

  return $slug;
}

# Auth helper: return user hashref if logged in, else 401 response
sub require_user_logged_in {
  # Deprecated: use session->read('user') directly in routes
  info "require_user_logged_in called (deprecated)";
  return 1;
}

# Auth helper: check if user can edit given article (owner/Admin/Editor)
sub user_can_edit_article {
  my ($user, $author, $allowed_roles) = @_;
  my $result = 0;
  
  # For new articles (no author yet), check role only
  if (!$author) {
    if ($user && grep { $_ eq $user->{role} } @$allowed_roles) {
      debug "Authorization check passed: role ", $user->{role}, " allowed for new article";
      $result = 1;
    }
  } elsif ($user && $author) {
    # For existing articles, check role or ownership
    my $author_name = $author->username();
    if (grep { $_ eq $user->{role} } @$allowed_roles) {
      debug "Authorization check passed: role ", $user->{role}, " allowed for article";
      $result = 1;
    } elsif ($user->{username} && $user->{username} eq $author_name && grep { $_ eq 'Owner' } @$allowed_roles) {
      debug "Authorization check passed: user ", $user->{username}, " is owner";
      $result = 1;
    }
  }
  return $result;
}

42;