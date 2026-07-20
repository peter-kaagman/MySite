package MySite;

use utf8;
use FindBin;
use Cwd qw(abs_path);
use Dancer2 with => {};
use Dancer2::Plugin::DBIC;
use MySite::Schema::Debug::Metrics;

use Data::Dumper;
use MySite::Observability;
use MySite::Index;
use MySite::User;
use MySite::Article;
use MySite::Page;
use MySite::ImageUpload;
use Dotenv;
use MySite::Category;
use MySite::Keyword;
use MySite::Hooks;
# Voor observability en metrics
use MySite::Observability;
use MySite::Observability::Store::Memcached;

use MySite::Profile;

use Log::Log4perl;
# Manually initialize Log::Log4perl from config if not already done
BEGIN {
  Dotenv->load if -f '.env';
  my $log_conf = eval { config->{log4perl}->{config} };
  if ($log_conf) {
    Log::Log4perl->init(\$log_conf);
  }
}



our $VERSION = '0.1';

debug "MySite version $VERSION starting up...";

# Config via session engine

my $store = MySite::Observability::Store::Memcached->new(
  server => ( 
    config->{'engines'}->{'session'}->{'Memcached'}->{'memcached_servers'}
    // 'localhost:11211',
  ),
  namespace_metrics => (
    config->{'engines'}->{'session'}->{'Memcached'}->{'namespace_metrics'}
    // 'mysite-metrics',
  ),
);
our $obs = MySite::Observability->new(
  store => $store,
);



my $storage = schema->storage;

$storage->debugobj(
    MySite::Schema::Debug::Metrics->new(
      obs => $obs
    )
);

$storage->debug(1);

my $config = config;
# debug "Logger config: " . ($config->{logger} // 'undef');
# debug "Log4perl config:\n" . ($config->{log4perl}->{config} // 'undef');

# set serializer => 'JSON';
# $ENV{DBIC_TRACE} = '1';



# Route-definitie
prefix '/category' => sub {
  get '/:slug' => \&MySite::Category::category_overview;
};

# Article routes
prefix '/article' => sub {
  # Specific routes first (these must come before the generic :category/:slug route)
  get  '/keywords'           => \&MySite::Article::_get_keywords;
  get  '/categories'         => \&MySite::Article::_get_categories;
  get  '/new'                => \&MySite::Article::_get_article_new;
  get  '/edit/:id'           => \&MySite::Article::_get_article_edit;
  get  '/list'               => \&MySite::Article::_article_list;
  get  '/:category/:slug'    => \&MySite::Article::_get_article_redirect; # oude route => redirect
  get  '/:slug'              => \&MySite::Article::_get_article;
  post '/add'                => \&MySite::Article::_post_article_new;
  post '/update/:field/:id'  => \&MySite::Article::_field_update;
  post '/keyword'            => \&MySite::Article::_handle_keyword;
  post '/category'           => \&MySite::Article::_handle_category;
};
get '/articles' => sub {
    # Redirect to /article/list
    return redirect "/article/list", 301;
};
#\&MySite::Article::_article_list;

# API Route definitie met prefix
prefix '/api' => sub {
    post '/upload-image' => \&MySite::ImageUpload::_upload_image;
    get  '/upload-image-config' => \&MySite::ImageUpload::image_upload_config_json;
};

# Keyword Route-definitie
prefix '/keyword' => sub {
  get '/:slug' => \&MySite::Keyword::_keyword_overview;
};


# Page Route-definitie
prefix '/page' => sub {
  get '/:slug' => \&MySite::Page::_page_content;
};

# User Routes
prefix '/user' => sub {
  # get '/login' => \&_login; # toont login pagina waar een keuze gemaakt kan worden voor OAuth provider
  get '/logout' => \&MySite::User::_logout;
  get '/login/ok' => \&MySite::User::_ok;
  get '/login/failed' => \&MySite::User::_failed;
  # get '/profile/:username' => \&_profile;
};

prefix '/auth' => sub {
  get '/callback/:provider' => \&MySite::User::_auth_callback;
  get '/:provider' => \&MySite::User::_auth_provider;
};


get '/' => \&MySite::Index::_index;
get '/health' => \&MySite::Index::_health;
get '/sitemap.xml' => \&MySite::Index::_sitemap;
get '/metrics' => \&MySite::Index::_prometheus_metrics;



true;
