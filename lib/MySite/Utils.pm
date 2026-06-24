package MySite::Utils;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;

use Exporter 'import';
# # use parent 'Exporter::Tiny';

our @EXPORT_OK = qw(render_markdown user_can_edit slugify unique_slug);
# our %EXPORT_TAGS = (
#   all => \@EXPORT_OK,
# );

# Use a Markdown rendering library to convert Markdown to HTML
sub render_markdown {
  my ($markdown) = @_;
  return '' unless defined $markdown && length $markdown;

  # Gebruik Pandoc via een systemcall voor conversie (GFM+link_attributes -> HTML)
  # Hiermee werken attributen als {:target="_blank"} in Markdown-links
  require IPC::Open2;
  my $pid = IPC::Open2::open2(my $out, my $in, 'pandoc', '-f', 'markdown+link_attributes', '-t', 'html');
  binmode $in,  ':utf8';
  binmode $out, ':utf8';
  print $in $markdown;
  close $in;
  local $/ = undef;
  my $html = <$out>;
  close $out;
  waitpid($pid, 0);

  # Post-process: Zet mermaid codeblokken om naar <pre class="mermaid">...</pre> en decodeer HTML-entiteiten
  if (defined $html) {
    use HTML::Entities ();
    # Vang zowel <pre><code class="language-mermaid">...</code></pre> als <pre class="mermaid"><code>...</code></pre>
    $html =~ s{<pre><code class="language-mermaid">(.*?)</code></pre>}{
      my $code = $1;
      $code = HTML::Entities::decode_entities($code);
      qq{<pre class="mermaid">$code</pre>};
    }gse;
    $html =~ s{<pre class="mermaid"><code>(.*?)</code></pre>}{
      my $code = $1;
      $code = HTML::Entities::decode_entities($code);
      qq{<pre class="mermaid">$code</pre>};
    }gse;
  }
  # debug "Markdown rendered to HTML: ", substr($html // '', 0, 500), '...';
  return $html // '';
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

  while (schema->resultset('Article')->find({ slug => $slug, deleted_at => undef })) {
    $slug = $base . '_' . $counter;
    $counter++;
  }

  return $slug;
}

# # Auth helper: return user hashref if logged in, else 401 response
# sub require_user_logged_in {
#   # Deprecated: use session->read('user') directly in routes
#   error "require_user_logged_in called (deprecated)";
#   return 0; # failure by default
# }

# Auth helper: check if user can edit given article (owner/Admin/Editor)
sub user_can_edit {
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