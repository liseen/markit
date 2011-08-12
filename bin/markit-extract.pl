#!/usr/bin/env perl

use strict;
use warnings;
#use utf8;

use JSON::XS;
use Getopt::Long;
use Params::Util qw /_HASH _ARRAY/;

use FindBin;
use lib "$FindBin::Bin/../../xhunter/perl/VDOM/lib";
use lib "$FindBin::Bin/../lib";

use Smart::Comments::JSON '###result';

use VDOM;
use Markit;

$Markit::Wrapper::Extractor::NeedToUNIXTime = 0;

use Markit::App::OutputFilter::BBS;

my $json_xs = JSON::XS->new->relaxed->pretty->allow_blessed->convert_blessed;

my $app = "qa";
my $wrapper_dir = "$FindBin::Bin/../wrappers";
my $browser;

GetOptions("wrapper-dir=s"  => \$wrapper_dir,
           "app=s"  => \$app,
           "browser"  => \$browser,
       );

my $vdom_file = shift or
    die "Usage: $0 --app=<app> --wrapper-dir=<dir> <infile>\n";

open my $in, $vdom_file or
    die "Can't open $vdom_file for reading: $!\n";

my $win = VDOM::Window->new->parse_file($in);
close $in;

my $url = $win->location;

my $app_extractor = new Markit::App::Extractor($wrapper_dir);

my $result;
eval {
    $result = $app_extractor->extract($app, $url, $win);
};
if ($@) {
    die "Failed extract, reason: $@";
}

my $groups = [];
Markit::Util::gen_groups_for_result($groups, $result, $app);

Markit::Util::delete_node_info_for_result($result);
if (exists $Markit::App::OutputFilter::Base::OutputFilters{$app}) {
    my $output_filter = $Markit::App::OutputFilter::Base::OutputFilters{$app};
    $output_filter->filter_output($url, $win, $result);
}

###result $result
my $summary = $json_xs->encode($result);

my $annotate_res = {
    #jump_to => $point,
    summary => $summary,
    groups => $groups,
    program => "Markit " . $Markit::VERSION,
    record_lists => $result,
};


my $outfile = $vdom_file . '.res';
open my $out, ">:encoding(utf8)", $outfile or
#open my $out, ">", $outfile or
    die "Cannot open $outfile for writing: $!\n";
print $out $json_xs->encode($annotate_res);
close $out;


