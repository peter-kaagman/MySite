package MySite;

use utf8;
use Dancer2 with => {};
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use MySite::Index;
use MySite::User;
use MySite::Article;

our $VERSION = '0.1';
# set serializer => 'JSON';
# $ENV{DBIC_TRACE} = '1';





get '/secured' => needs login => sub {
  my $user = session->read('user');
  debug "Dit is secured";
  debug Dumper $user;
  template 'index' => {
    'title' => 'Secured',
    'user' => session->read('user')

  };
};



true;
