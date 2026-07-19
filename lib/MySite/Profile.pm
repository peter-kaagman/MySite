package MySite::Profile;

use Dancer2 appname => 'MySite';
use Dancer2::Plugin::DBIC;
use MySite::Utils qw(render_markdown user_can_edit slugify unique_slug datetime_to_machine datetime_to_human);
use MySite::ErrorHandler qw(db_guard json_error template_error user_context);
use Digest::MD5 qw(md5_hex);


sub _show_profile {
    my $slug = route_parameters->get('slug');
    my $user = schema->resultset('User')->find({ slug => $slug });

    # If the user is not found, return a 404 error with a custom template
    if (!$user) {
        return template_error('profile/profile_not_found.tt', { slug => $slug });
    }

    my @recent_articles = $user->articles->search(
        {},
        {
            order_by => { -desc => 'created' },
            rows     => 5,
        }
    )->all;

    my @socials = $user->user_socials->search(
        {},
        {
            order_by => 'display_order',
        }
    )->all;


    my $breadcrumbs = [
        { 
            name => 'Home', 
            url => '/' 
        },{ 
            name => $user->user_profile->display_name, 
            url => $user->url 
        },
    ];

    return template 'profile/profile.tt' => {
        profile_for => $user,
        gravatar_hash => $user->user_profile->email ? md5_hex(lc($user->user_profile->email)) : '',
        render_markdown => \&MySite::Utils::render_markdown,
        recent_articles => \@recent_articles,
        page_type => 'profile',
        breadcrumbs => $breadcrumbs,
        socials => \@socials,
    };
}

prefix '/profile' => sub {
  get '/:slug' => \&_show_profile;
};


1;
