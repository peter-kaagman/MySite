package MySite::ErrorHandler;

use v5.11;
use utf8;
use Dancer2 appname => 'MySite', with => {};
use Exporter 'import';

our @EXPORT_OK = qw(db_guard json_error template_error user_context);

=head1 NAME

MySite::ErrorHandler - Centralized error handling and logging utilities

=head1 DESCRIPTION

Provides consistent error handling for database operations, JSON responses,
and template rendering with proper logging context.

=head1 SUBROUTINES

=head2 db_guard

Wraps a database operation with error handling and logging.

  my ($ok, $result) = db_guard(
    action => 'create article',
    user => $user_hashref,
    code => sub { ... }
  );

Returns a list: (success_flag, result). On error, logs and returns (0, undef).

=cut

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
  
  debug "$action succeeded - $context";
  return wantarray ? (1, $result) : 1;
}

=head2 json_error

Returns a JSON error response with appropriate HTTP status.

  return json_error(
    message => 'Invalid input',
    status => 400,
    details => 'Optional details'
  );

=cut

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

=head2 template_error

Returns an error template with proper context.

  return template_error(
    title => 'Not Found',
    error => 'Article not found',
    status => 404
  );

=cut

sub template_error {
  my (%args) = @_;
  my $title = $args{title} // 'Error';
  my $error = $args{error} // 'An error occurred';
  my $status = $args{status} // 500;
  
  status $status;
  return template 'error' => {
    title => $title,
    user => session->read('user'),
    error_content => $error
  };
}

=head2 user_context

Generates a logging context string with user information.

  my $ctx = user_context($user_hashref);
  # Returns: "user=username (id=123)" or "anonymous"

=cut

sub user_context {
  my ($user) = @_;
  
  return 'anonymous' unless $user;
  
  my $ctx = "user=$user->{username}";
  $ctx .= " (id=$user->{id})" if $user->{id};
  $ctx .= " (role=$user->{role})" if $user->{role};
  
  return $ctx;
}

42;
