package MySite;

use utf8;
use FindBin;
use Cwd qw(abs_path);
use Dancer2 with => {};
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use MySite::Index;
use MySite::User;
use MySite::Article;

our $VERSION = '0.1';

# ISSUE #34 FIX: Use FindBin to resolve absolute database path
# This ensures database connection works regardless of startup working directory
# (fixes issues with systemd, Docker entrypoint, or other unusual startup environments)
{
    my $app_root = abs_path("$FindBin::Bin/..");
    my $db_path = "$app_root/db/mysite.sqlite";
    
    # Override the DBIC dsn with absolute path
    # This is set in config.yml as relative, but we convert it to absolute here
    my $config = config;
    if ($config->{plugins}->{DBIC}->{default}->{dsn} =~ /dbname=db\/mysite\.sqlite/) {
        my $original_dsn = $config->{plugins}->{DBIC}->{default}->{dsn};
        $config->{plugins}->{DBIC}->{default}->{dsn} =~ s|dbname=db/mysite\.sqlite|dbname=$db_path|;
        debug "DBIC: Database path resolved to absolute: $db_path";
    }
}

# set serializer => 'JSON';
# $ENV{DBIC_TRACE} = '1';





get '/secured' => sub {
  my $user = session->read('user');
  debug "Dit is secured";
  debug Dumper $user;
  template 'index' => {
    'title' => 'Secured',
    'user' => session->read('user')

  };
};

# Health check endpoint for Docker
get '/health' => sub {
  content_type 'application/json';
  return to_json({ 
    status => 'ok', 
    version => $VERSION,
    timestamp => time()
  });
};

true;
