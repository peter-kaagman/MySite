package MySite::Hooks;

use Dancer2 appname => 'MySite';
use Time::HiRes;

use Data::UUID;

my $uuid_gen = Data::UUID->new();

# Hooks
sub before_template_render_hook {
  my $tokens = shift;

  my $base_url = config->{base_url}
    ? config->{base_url}
    : request->base;
  $base_url =~ s{/$}{};
  $tokens->{base_url} = $base_url;

  # Add the current path to the tokens for canonical URL generation
  $tokens->{path} = request->path;

  # Add the user session to the tokens for template access
  $tokens->{user} = session->read('user');
}
hook before_template_render => \&before_template_render_hook;

hook before => sub {
  var request_start_time => Time::HiRes::time();
  var request_id => $uuid_gen->create_str();
};

hook after => sub {
  my $response = shift;
  my $request_start_time = var('request_start_time');
  my $request_end_time = Time::HiRes::time();
  my $duration = $request_end_time - $request_start_time;

  $MySite::obs->event(
    domain      => 'http',
    action      => 'request',

    request_id  => var('request_id'),

    path        => request->path,
    method      => request->method,
    status      => $response->status,

    user_agent  => request->user_agent,
    remote_ip   => request->address,

    duration_ms => int($duration * 1000),
  );
};
