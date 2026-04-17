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
use MySite::Page;
use MySite::ImageUpload;
use Dotenv;

our $VERSION = '0.1';

use Log::Log4perl;
# Manually initialize Log::Log4perl from config if not already done
BEGIN {
  Dotenv->load if -f '.env';
  my $log_conf = eval { config->{log4perl}->{config} };
  if ($log_conf) {
    Log::Log4perl->init(\$log_conf);
  }
}
my $config = config;
debug "Logger config: " . ($config->{logger} // 'undef');
debug "Log4perl config:\n" . ($config->{log4perl}->{config} // 'undef');

# set serializer => 'JSON';
# $ENV{DBIC_TRACE} = '1';

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
