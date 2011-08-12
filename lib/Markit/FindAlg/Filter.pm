package Markit::FindAlg::Filter;

use strict;
use warnings;

use VDOM::Node;
use List::Util qw( first );

use base 'Markit::FindAlg::Base';

__PACKAGE__->register('filter');


sub find_nodes {
    my ($class, $elem, $args) = @_;

    my $group = [];
    for my $child ($elem->childNodes) {
        next if $child->nodeType != $VDOM::Node::ELEMENT_NODE;
        push @$group, $child;

        my $sub_g = $class->find_nodes($child, $args);

        push @$group, @$sub_g;
    }

    return $group;
}

1;
