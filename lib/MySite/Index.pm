package MySite::Index;

use utf8;
use Dancer2 appname => 'MySite', with => {};
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use Template;
use FindBin;
use MySite::Utils qw(render_markdown);
use MySite::ErrorHandler qw(db_guard template_error);


sub _index {
    my ($db_ok, $articles) = db_guard(
      action => 'fetch articles for homepage',
      user => session->read('user'),
      code => sub {
        return schema->resultset('Article')->search(
          {},
          { order_by => {'-desc' => ['created']} }
        );
      }
    );
    
    unless ($db_ok) {
      return template_error(
        title => 'Database Error',
        error => 'Could not load articles',
        status => 500
      );
    }
    
    debug "Found " . ($articles ? $articles->count : 0) . " articles";
    
    template 'article/list' => {
        'title' => 'MySite',
        'user' => session->read('user'),
        'articles' => $articles,
        'render_markdown' => \&MySite::Utils::render_markdown,
    };
}

get '/' => \&_index;

42;