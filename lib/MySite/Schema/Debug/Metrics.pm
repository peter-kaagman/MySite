package MySite::Schema::Debug::Metrics;

use Moo;
extends 'DBIx::Class::Storage::Statistics';

use Time::HiRes qw(gettimeofday tv_interval);

has obs => (
    is       => 'ro',
    required => 1,
);

sub query_start {
    my ($self, $sql, @bind) = @_;

    $self->{_started} = [ gettimeofday ];

    return;
}

sub query_end {
    my ($self, $sql, @bind) = @_;

    return unless $self->{_started};

    my $duration_ms =
        tv_interval($self->{_started}) * 1000;

    delete $self->{_started};

    $self->obs->event(
        domain      => 'database',
        action      => 'query',
        duration_ms => $duration_ms,
    );

    return;
}

1;