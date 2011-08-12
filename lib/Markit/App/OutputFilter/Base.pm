package Markit::App::OutputFilter::Base;

use strict;
use warnings;

our %OutputFilters;

sub filter_output {
    my ($self, $url, $win, $result) = @_;

    return $result;
}

sub register {
    my $class = shift;

    for my $app (@_) {
        $OutputFilters{$app} = $class;
    }
}

1;
