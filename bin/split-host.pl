#!/usr/bin/env perl
#
#

my $host = shift or 
    die "no host specified\n";

while (<STDIN>) {
    my ($doc_id, $url, $other) = split /\t/, $_, 3;

    if ($url =~ /$host/) {
        print $_;
    }
}
