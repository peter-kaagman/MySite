package MySite::Observability;

use Moo;
use JSON qw(encode_json);
use Time::HiRes qw(time);
use IO::Handle;
use Data::Dumper;

STDOUT->autoflush(1);

has histograms => (
    is => 'ro',
    default => sub {
        {
            mysite_http_request_duration_ms => [
                10, 20, 50, 100, 200, 500, 1000, 2000,
            ],

            mysite_db_query_duration_ms => [
                1, 2, 5, 10, 50, 100,
            ],

            mysite_markdown_render_duration_ms => [
                10, 20, 50, 100, 200, 500, 1000, 2000,
            ],
        };
    },
);

has store => (
    is       => 'ro',
    required => 1,
);

sub event {
    my ($self, %event) = @_;
    # print "Observability event: ", Dumper(\%event), "\n";

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
    elsif ($domain eq 'markdown') {
        $self->_handle_markdown_event(%event);
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
            . ($self->store->get('mysite_http_requests_total') // 0);

    push @out,
        "# TYPE mysite_db_queries_total counter",
        "mysite_db_queries_total "
            . ($self->store->get('mysite_db_queries_total') // 0);

    push @out,
        "# TYPE mysite_crawler_requests_total counter",
        "mysite_crawler_requests_total "
            . ($self->store->get('mysite_crawler_requests_total') // 0);
   push @out,
        "# TYPE mysite_markdown_render_total counter",
        "mysite_markdown_render_total "
            . ($self->store->get('mysite_markdown_render_total') // 0);

    #
    # Histograms
    #

    foreach my $name (
        sort keys %{ $self->histograms }
    ) {

        push @out, "# TYPE $name histogram";

        foreach my $bucket (
            @{ $self->_buckets_for_histogram($name) }
        ) {
            push @out,
                qq{$name\_bucket{le="$bucket"} }
                . ($self->store->get(
                    "${name}_bucket_$bucket"
                ) // 0);
        }

        push @out,
            qq{$name\_bucket{le="+Inf"} }
            . ($self->store->get(
                "${name}_bucket_Inf"
            ) // 0);

        push @out,
            "${name}_sum "
            . ($self->store->get(
                "${name}_sum"
            ) // 0),

            "${name}_count "
            . ($self->store->get(
                "${name}_count"
            ) // 0);
    }

    return join("\n", @out) . "\n";
}

sub _emit_loki {
    my ($self, %event) = @_;

    if ($ENV{PRODUCTION}) {
        print STDOUT encode_json({
            source  => 'observe',
            version => 1,
            ts      => int(time() * 1000),
            %event,
        }) . "\n";
    }

    return;
}

sub _handle_http_event {
    my ($self, %event) = @_;
    # print "Handling HTTP event: ", Dumper(\%event), "\n";

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

sub _handle_markdown_event {
    my ($self, %event) = @_;

    return unless ($event{action} // '') eq 'render';

    $self->_inc_counter(
        'mysite_markdown_render_total'
    );

    if (defined $event{duration_ms}) {
        $self->_observe_histogram(
            'mysite_markdown_render_duration_ms',
            $event{duration_ms}
        );
    }

    return;
}

sub _inc_counter {
    my ($self, $name) = @_;
    # print "Incrementing counter: $name\n";

    $self->store->inc($name);

    return;
}

sub _observe_histogram {
    my ($self, $name, $value) = @_;

    foreach my $bucket (
        @{ $self->_buckets_for_histogram($name) }
    ) {
        if ($value <= $bucket) {
            $self->store->inc(
                "${name}_bucket_$bucket"
            );
        }
    }

    $self->store->inc(
        "${name}_bucket_Inf"
    );

    $self->store->add(
        "${name}_sum",
        $value
    );

    $self->store->inc(
        "${name}_count"
    );

    return;
}

sub _buckets_for_histogram {
    my ($self, $name) = @_;

    my $buckets = $self->histograms->{$name};

    die "Unknown histogram: $name"
        unless $buckets;

    return $buckets;
}


1;
