package Markit::FindAlg::Base;

use strict;
use warnings;

our %FindAlgs;

sub find_nodes {
    my ($class, $elem, $args) = @_;

    return [];
}

sub register {
    my $class = shift;

    for my $alg (@_) {
        $FindAlgs{$alg} = $class;
    }
}

1;
