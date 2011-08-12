package Markit::App::OutputFilter::BBS;

use strict;
use warnings;

use VDOM::Node;
use List::Util qw( first );

use base 'Markit::App::OutputFilter::Base';

__PACKAGE__->register('bbs');

sub filter_output {
    my ($self, $url, $win, $result) = @_;
    no warnings 'uninitialized';

    if ($result) {
        my $page_title = $win->document->title;

        my $title;
        if (!exists $result->{title}->{text}) {
            my @ts = split /\s*[_,|-]+\s*/, $page_title;
            for my $t (@ts) {
                next if !$t;
                $t =~ s/^\s+//s;
                $t =~ s/\s+$//s;
                next if !$t;
                next if $t =~ /论坛\w?$/;
                next if $t =~ /^\W+\w+\.\w+\.\w+\W+$/;

                $title = $t;
                last;
            }
            #warn $title;
            $result->{title}->{text} = $title;
        }
    }

    return $result;
}

1;
