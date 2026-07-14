package MySite::Observability::Store::Memcached;

use Moo;
use Cache::Memcached;

has server => (
    is       => 'ro',
    required => 1,
);
has namespace_metrics => (
    is       => 'ro',
    required => 1,
);


has client => (
    is      => 'lazy',
    builder => '_build_client',
    init_arg => undef,
);

sub _build_client {
    my ($self) = @_;

    warn "CLIENT SERVER=" . $self->server;
    warn "CLIENT NAMESPACE=" . $self->namespace_metrics;

    return Cache::Memcached->new(
        servers         => [ $self->server ],
        namespace       =>  $self->namespace_metrics,
    );
}

sub get {
    my ($self, $key) = @_;

    return $self->client->get($key);
}

sub set {
    my ($self, $key, $value) = @_;

    my $rc = $self->client->set($key, $value);

    warn "MEMCACHED SET key=$key value=$value rc=" .
         (defined $rc ? $rc : 'undef');

    return $rc;
}


sub inc {
    my ($self, $key, $amount) = @_;

    $amount //= 1;

    my $new = $self->client->incr($key, $amount);

    warn "MEMCACHED INCR1 key=$key amount=$amount result=" .
         (defined $new ? $new : 'undef');

    return $new if defined $new;

    my $rc = $self->client->set($key, 0);

    warn "MEMCACHED SET key=$key value=0 rc=" .
         (defined $rc ? $rc : 'undef');

    $new = $self->client->incr($key, $amount);

    warn "MEMCACHED INCR2 key=$key amount=$amount result=" .
         (defined $new ? $new : 'undef');

    return $new;
}


sub add {
    my ($self, $key, $amount) = @_;

    $amount //= 0;

    my $current = $self->get($key) // 0;
    my $new = $current + $amount;

    my $rc = $self->client->set($key, $new);

    warn "MEMCACHED ADD key=$key current=$current add=$amount new=$new rc=" .
         (defined $rc ? $rc : 'undef');

    return $new;
}
1;