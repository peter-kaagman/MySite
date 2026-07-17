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

    return $self->client->set($key, $value);
}


sub inc {
    my ($self, $key, $amount) = @_;

    $amount //= 1;

    return $self->client->incr($key, $amount);

}


sub add {
    my ($self, $key, $amount) = @_;

    $amount //= 0;

    my $current = $self->get($key) // 0;
    my $new = $current + $amount;

    return $self->client->set($key, $new);
}
1;