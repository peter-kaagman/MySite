package MySite::ErrorHandler;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Exporter 'import';

our @EXPORT_OK = qw(db_guard json_error template_error user_context);

sub db_guard {
  my (%args) = @_;
  my $action = $args{action} // 'database operation';
  my $user = $args{user};
  my $code = $args{code} // sub { return 1; };
  
  my $context = user_context($user);
  
  my $result;
  eval {
    $result = $code->();
    1;
  } or do {
    my $error = $@ || 'Unknown error';
    error "$action failed - $context - Error: $error";
    return wantarray ? (0, undef) : 0;
  };
  
  return wantarray ? (1, $result) : 1;
}


sub json_error {
  my (%args) = @_;
  my $message = $args{message} // 'An error occurred';
  my $status = $args{status} // 500;
  my $details = $args{details};
  
  status $status;
  my $response = {
    success => 0,
    error => $message
  };
  $response->{details} = $details if defined $details;
  
  return to_json($response);
}


sub template_error {
  my (%args) = @_;


  $MySite::obs->event(
    domain      => $args{domain} // 'error',
    action      => $args{action} // 'template_error',
    request_id  => var('request_id'),
    path        => request->path,
    method      => request->method,
    status      => $args{status} // 500,
    user_agent  => request->user_agent,
    remote_ip   => request->address,
    title       => $args{title} // 'Onbekende error',
    error       => $args{error} // 'Een onbekende error occurred',
    level       => $args{level} // 'error',
    );
  
  status $args{status} // 500;
  return template 'error' => {
    title => $args{title} // 'Error',
    error_content => $args{error} // 'An error occurred'
  };
}


sub user_context {
  my ($user) = @_;
  
  return 'anonymous' unless $user;
  
  my $ctx = "user=$user->{username}";
  $ctx .= " (id=$user->{id})" if $user->{id};
  $ctx .= " (role=$user->{role})" if $user->{role};
  
  return $ctx;
}

42;
