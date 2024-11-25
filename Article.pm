package MySite::Schema::ResultSet::Article;
use strict;
use warnings;
use Data::Dumper;
use base 'DBIx::Class::ResultSet';

sub returnURL {
    my ($self, $which) = @_;
    my $blaat =$self->find(
        {article_id => $which}
    );
    my $result = $blaat->slug;
    print "\n>>$result<<\n";
    return $result;
}
1;