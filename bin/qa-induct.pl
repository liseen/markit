#!/usr/bin/env perl

use strict;
use warnings;

use Smart::Comments '###';
use FindBin;
use JSON::XS;
use File::Slurp;
use File::Spec::Functions;

use Getopt::Long;

use lib "$FindBin::Bin/../../xhunter/perl/VDOM/lib";
use lib "$FindBin::Bin/../lib";

use VDOM;
use Markit;

my $json_xs = JSON::XS->new->pretty->allow_blessed->convert_blessed;

my $host;
my $pattern_name;
my $pattern_dir;

GetOptions("host=s" => \$host,
           "pattern-dir=s"  => \$pattern_dir,
           "pattern=s"  => \$pattern_name);

if (!$host) {
    die "No host specified!\n";
}

if (!$pattern_name) {
    die "No pattern name specified!\n";
}

if (!$pattern_dir) {
    die "No pattern directory specified!\n";
}


my @anno_datas;

my $pattern_file = catfile($pattern_dir, $pattern_name . ".pattern");
my $anno_file = catfile($pattern_dir, $pattern_name . "-" . $host. ".anno");
my $vdom_file = catfile($pattern_dir, $pattern_name . "-" . $host. ".vdom");

my $pattern_content = read_file($pattern_file);
my $pattern_anno = read_file($anno_file);
my $pattern_vdom = read_file($vdom_file);

my $pattern_json = $json_xs->decode($pattern_content);

### $pattern_json
my $pattern = Markit::Pattern::build($pattern_name, $pattern_json);

my $win = VDOM::Window->new;
$win->parse(\$pattern_vdom);

my $an = Markit::Pattern::build($pattern_name, $pattern_anno);
$an->mark($win);

push @anno_datas, $an;

if (!@anno_datas) {
    die "No this host's marked data";
}
my $inductor = new Markit::Wrapper::Inductor;
my $wrapper = $inductor->induct($pattern, \@anno_datas);
$wrapper->{host} = $host;
### $wrapper
#
my $wrapper_json = $json_xs->encode($wrapper);

### $wrapper_json;

