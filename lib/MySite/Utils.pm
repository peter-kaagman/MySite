package MySite::Utils;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;
use Text::Markdown 'markdown';
use Exporter 'import';
# # use parent 'Exporter::Tiny';

our @EXPORT_OK = qw(render_markdown require_user_logged_in user_can_edit_article slugify unique_slug);
# our %EXPORT_TAGS = (
#   all => \@EXPORT_OK,
# );

# Use a Markdown rendering library to convert Markdown to HTML
sub render_markdown {
  my ($text) = @_;
  my $html = markdown($text);
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
  my $base = _slugify($base_text);
  my $slug = $base;
  my $counter = 2;

  while (schema->resultset('Article')->find({ slug => $slug })) {
    $slug = $base . '_' . $counter;
    $counter++;
  }

  return $slug;
}

# # Auth helper: return user hashref if logged in, else 401 response
sub require_user_logged_in {
  # my $user = session->read('user');
  # # unless ($user) {
  # #   status 401;
  # #   content_type 'application/json';
  # #   return to_json({ error => 'Unauthorized' });
  # # }
  # return ($user && $user->{username}) ? $user : undef;
  debug "Dit zou niet meer aangeroep moeten worden";
  return 1;
}

# Auth helper: check if user can edit given article (owner/Admin/Editor)
sub user_can_edit_article {
  my ($user, $author, $allowed_roles) = @_;
  my $result = 0;
  
  # For new articles (no author yet), check role only
  if (!$author) {
    if ($user && grep { $_ eq $user->{role} } @$allowed_roles) {
      debug "Role ", $user->{role}, " is allowed for new article";
      $result = 1;
    }
  } elsif ($user && $author) {
    # For existing articles, check role or ownership
    my $author_name = $author->username();
    # (1, 'Admin'),
    # (2, 'Editor'),
    # (3, 'Writer'),
    # (4, 'Visitor')
    if (grep { $_ eq $user->{role} } @$allowed_roles) {
      debug "Role ", $user->{role}, " is allowed";
      $result = 1;
    } elsif ($user->{username} && $user->{username} eq $author_name && grep { $_ eq 'Owner' } @$allowed_roles) {
      debug "User ", $user->{username}, " is owner and allowed";
      $result = 1;
    }
  }
  return $result;
}

42;