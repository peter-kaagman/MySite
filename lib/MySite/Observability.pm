package MySite::Observability;

use Moo;
use JSON qw(encode_json);
use Time::HiRes qw(time);
use IO::Handle;

STDOUT->autoflush(1);

#
# Counters
#

has counters => (
    is      => 'ro',
    default => sub {
        {
            mysite_http_requests_total  => 0,
            mysite_db_queries_total     => 0,
            mysite_crawler_requests_total => 0,
        };
    },
);

#
# Histograms
#

has histograms => (
    is      => 'ro',
    default => sub {
        {
            mysite_http_request_duration_ms => {
                buckets => {
                    10     => 0,
                    50     => 0,
                    100    => 0,
                    250    => 0,
                    500    => 0,
                    1000   => 0,
                    '+Inf' => 0,
                },
                sum   => 0,
                count => 0,
            },

            mysite_db_query_duration_ms => {
                buckets => {
                    10     => 0,
                    50     => 0,
                    100    => 0,
                    250    => 0,
                    500    => 0,
                    1000   => 0,
                    '+Inf' => 0,
                },
                sum   => 0,
                count => 0,
            },
        };
    },
);

#
# Public API
#

sub event {
    my ($self, %event) = @_;

    $self->_emit_loki(%event);

    my $domain = $event{domain} // '';

    if ($domain eq 'http') {
        $self->_handle_http_event(%event);
    }
    elsif ($domain eq 'database') {
        $self->_handle_database_event(%event);
    }
    elsif ($domain eq 'crawler') {
        $self->_handle_crawler_event(%event);
    }

    return;
}

sub prometheus_export {
    my ($self) = @_;

    my @out;

    #
    # Counters
    #

    push @out,
        "# TYPE mysite_http_requests_total counter",
        "mysite_http_requests_total "
            . $self->counters->{mysite_http_requests_total};

    push @out,
        "# TYPE mysite_db_queries_total counter",
        "mysite_db_queries_total "
            . $self->counters->{mysite_db_queries_total};

    push @out,
        "# TYPE mysite_crawler_requests_total counter",
        "mysite_crawler_requests_total "
            . $self->counters->{mysite_crawler_requests_total};

    #
    # Histograms
    #

    foreach my $name (
        qw(
            mysite_http_request_duration_ms
            mysite_db_query_duration_ms
        )
    ) {
        my $hist = $self->histograms->{$name};

        push @out, "# TYPE $name histogram";

        foreach my $bucket (
            10, 50, 100, 250, 500, 1000, '+Inf'
        ) {
            push @out,
                qq{$name\_bucket{le="$bucket"} }
                . ($hist->{buckets}{$bucket} // 0);
        }

        push @out,
            "${name}_sum "   . $hist->{sum},
            "${name}_count " . $hist->{count};
    }

    return join("\n", @out) . "\n";
}

#
# Loki
#

sub _emit_loki {
    my ($self, %event) = @_;

    print STDOUT encode_json({
        source  => 'observe',
        version => 1,
        ts      => int(time() * 1000),
        %event,
    }) . "\n";

    return;
}

#
# Domain handlers
#

sub _handle_http_event {
    my ($self, %event) = @_;

    return unless ($event{action} // '') eq 'request';

    $self->_inc_counter(
        'mysite_http_requests_total'
    );

    if (defined $event{duration_ms}) {
        $self->_observe_histogram(
            'mysite_http_request_duration_ms',
            $event{duration_ms}
        );
    }

    return;
}

sub _handle_database_event {
    my ($self, %event) = @_;

    return unless ($event{action} // '') eq 'query';

    $self->_inc_counter(
        'mysite_db_queries_total'
    );

    if (defined $event{duration_ms}) {
        $self->_observe_histogram(
            'mysite_db_query_duration_ms',
            $event{duration_ms}
        );
    }

    return;
}

sub _handle_crawler_event {
    my ($self, %event) = @_;

    return unless ($event{action} // '') eq 'visit';

    $self->_inc_counter(
        'mysite_crawler_requests_total'
    );

    return;
}

#
# Metrics helpers
#

sub _inc_counter {
    my ($self, $name) = @_;

    $self->counters->{$name}++;

    return;
}

sub _observe_histogram {
    my ($self, $name, $value) = @_;

    my $hist = $self->histograms->{$name}
        or return;

    foreach my $bucket (
        10, 50, 100, 250, 500, 1000
    ) {
        if ($value <= $bucket) {
            $hist->{buckets}{$bucket}++;
        }
    }

    $hist->{buckets}{'+Inf'}++;

    $hist->{sum}   += $value;
    $hist->{count} += 1;

    return;
}

1;