#!/usr/bin/env perl

use strict;
use warnings;
#use utf8;

use JSON::XS;
use Getopt::Long;
use Params::Util qw /_HASH _ARRAY/;
use Encode qw/_utf8_on _utf8_off/;
use FindBin;
#use lib "$FindBin::Bin/../../xhunter/perl/VDOM/lib";
use lib "$FindBin::Bin/../lib";

#use Smart::Comments::JSON '###result';
#use Smart::Comments::JSON '#d';
use VDOM;
use Markit;

my $json_xs = JSON::XS->new->utf8->relaxed->allow_blessed->convert_blessed;

my $app = "qa";
my $wrapper_dir = "$FindBin::Bin/../wrappers";

GetOptions("wrapper-dir=s"  => \$wrapper_dir,
           "app=s"  => \$app
        );

my $batch_vdom_file = shift or
    die "Usage: $0 --app=<app> --wrapper-dir=<dir> <infile>\n";

open my $in, $batch_vdom_file or
    die "Can't open $batch_vdom_file for reading: $!\n";

my $json_coder = JSON::XS->new->utf8->pretty;

my $app_extractor = new Markit::App::Extractor($wrapper_dir);

my $no = 1;
while (<$in>) {
    my ($doc_id, $url, $datasource, $vdom) = split /\t/;
    next if !$vdom;

    $vdom =~ s/\001/\n/gs;

    my $win;
    eval {
        $win = VDOM::Window->new->parse(\$vdom);
    };
    if ($@) {
        warn "invalid vdom: $url";
        next;
    }

    my $status;
    my $records = [];

    my $result;
    eval {
        $result = $app_extractor->extract($app, $url, $win);
    };
    if ($@) {
        $result = "failed : $@";
        warn "Failed extract $url, reason: $@\n";
        $status = 1;
        push @$records, [$url];
    } elsif (keys %$result > 0) {
        Markit::Util::delete_node_info_for_result($result);
        $records = Markit::Util::process_result_for_surfer($app, $url, $result);
        $status = 0;
    } else {
        $status = 2;
        push @$records, [$url];
        $result = "doesn't have anything";
    }

    for my $rec (@$records) {
        no warnings 'uninitialized';
        my $r = join "\t", @$rec;
        _utf8_off($r);
        print $no . "\t" . $status . "\t" . $r . "\n";
    }

    #d $no
    #d $url
    #d $result


    #my $summary = $json_xs->encode($result);
    #$summary =~ s/\n//gs;
    #_utf8_on($summary);
    #print "$no\t$url\t$summary\n";
    $no++;
}

close $in;

#
