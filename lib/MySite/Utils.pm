package MySite::Utils;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Text::Markdown 'markdown';

sub render_markdown {
  my ($text) = @_;
  # Use a Markdown rendering library to convert Markdown to HTML
  my $html = markdown($text);
  return $html;
}



42;