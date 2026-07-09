package MySite::Page;

use Dancer2 appname => 'MySite';
use Dancer2::Plugin::DBIC;
use MySite::Utils qw(render_markdown);

# Route handler voor statische pagina's
sub _page_content {
    my $slug = route_parameters->get('slug');
    debug "Gevraagd slug: $slug";
    my $page = schema->resultset('Page')->find({ slug => $slug });
    
    unless ($page) {
        status 404;
        return template 'error.tt', { message => "Pagina niet gevonden" };
    }

    # Haal de laatste gepubliceerde content op
    my $content = schema->resultset('PageContent')->search({
        pageid   => $page->page_id,
        published => { '!=', undef },
    }, {
        order_by => { -desc => 'published' },
        rows     => 1,
    })->first;

    # debug "Gevonden pagina: " . $page->name; debug "Laatste content gepubliceerd op: " . ($content ? $content->published : 'geen content gevonden');
    # debug  $content ? "Content: " . $content->content : "Geen content beschikbaar";
    debug "Page allow_indexing: " . ($page->allow_indexing ? 'true' : 'false');
    
    return template 'page.tt', {
        'meta_description' => $page->meta_description || $page->name,
        'title' => $page->meta_title || $page->name,
        'content' => $content,
        'render_markdown' => \&MySite::Utils::render_markdown,
        'allow_indexing' => $page->allow_indexing,
    };
};



1;
