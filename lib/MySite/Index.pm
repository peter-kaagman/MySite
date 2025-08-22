package MySite::Index;

use utf8;
use Dancer2 appname => 'MySite';
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use Template;
use FindBin;
use MySite::Utils qw(render_markdown);


sub _index {
    my $articles = schema->resultset('Article')->search(
        {},
    {
        order_by => {'-desc' => ['created']},
    }
    );
    # debug Dumper $articles;
    template 'article/list' => {
        'title' => 'MySite',
        'user' => session->read('user'),
        'articles' => $articles,
        'render_markdown' => \&MySite::Utils::render_markdown,
    };
}

get '/' => \&_index;

42;