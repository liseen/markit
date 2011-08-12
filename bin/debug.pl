#!/usr/bin/env perl

use strict;
use warnings;

my $url=shift;

while (<STDIN>) {
    my (undef, $u, undef, $vdom) = split /\t/, $_;
    if ($u eq $url) {
        $vdom =~ s/\001/\n/gs;
        print $vdom;
    }

}

