package MySite::Hooks;

use Dancer2 appname => 'MySite';
use Time::HiRes;

use Data::UUID;

my $uuid_gen = Data::UUID->new();

# Hooks
hook before_template_render => sub {
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

  # metrics
  var template_request_start_time => Time::HiRes::time();
};

hook after_template_render => sub {
  my $end_time = Time::HiRes::time();
  my $start_time = var('template_request_start_time');
  my $duration = $end_time - $start_time;
  $MySite::obs->event(
    domain      => 'template',
    action      => 'render',
    request_id  => var('request_id'),
    duration_ms => int($duration * 1000),
  );
};

hook before => sub {
  # debug "Request started: ", request->method, " ", request->path;
  var request_start_time => Time::HiRes::time();
  # debug "Assigned request_start_time: ", var('request_start_time');
  var request_id => $uuid_gen->create_str();
  # debug "Assigned request_id: ", var('request_id');

};

hook after => sub {
  my $response = shift;
  my $request_start_time = var('request_start_time');
  my $request_end_time = Time::HiRes::time();
  my $duration = $request_end_time - $request_start_time;
  # debug "Request ended: ", request->method, " ", request->path, " (", $response->status, ") in ", sprintf("%.3f", $duration), " seconds";

  # Metric
  $MySite::obs->event(
    domain      => 'http',
    action      => 'request',
    request_id  => var('request_id'),
    duration_ms => int($duration * 1000),
  );

  # Log event for Loki
  $MySite::obs->event(
    domain      => 'http_request',
    action      => 'request',
    request_id  => var('request_id'),
    path        => request->path,
    method      => request->method,
    status      => $response->status,
    user_agent  => request->user_agent,
    remote_ip   => request->address,
  );
};

1;