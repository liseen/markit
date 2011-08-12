#!/usr/bin/env perl

use strict;
use warnings;

use Smart::Comments '###';
use FindBin;
use JSON::XS;
use Getopt::Long;

use lib "$FindBin::Bin/../../xhunter/perl/VDOM/lib";
use lib "$FindBin::Bin/../lib";

use VDOM;
use Markit;
use TokyoCabinet;

my $json_xs = JSON::XS->new->pretty->allow_blessed->convert_blessed;

my $pat_name = 'title';
my $pattern = {
        "children" => {
            title => {
               occur_type => "single",
               type => "text"
            }
        }
     };

$pattern = Markit::Pattern->new->build($pattern);

my $host;
GetOptions("host=s" => \$host);
if (!$host) {
    die "No host specified!\n";
}

my @anno_datas;

my $tdb = TokyoCabinet::TDB->new();
# open the database
if(!$tdb->open("$ENV{HOME}/title.tct", $tdb->OWRITER | $tdb->OCREAT)){
    my $ecode = $tdb->ecode();
    printf STDERR ("open error: %s\n", $tdb->errmsg($ecode));
}
### $host
my $qry = TokyoCabinet::TDBQRY->new($tdb);
$qry->addcond("host", $qry->QCSTROR, $host);
$qry->addcond("type", $qry->QCSTROR, "marked_data");
my $res = $qry->search();
foreach my $rkey (@$res){
    my $rcols = $tdb->get($rkey);
    my $an_data = $json_xs->decode($rcols->{an});
    my $vdom = $rcols->{vdom};
    my $win = VDOM::Window->new;
    $win->parse(\$vdom);

    my $an = Markit::Annotation->new->build($an_data);
    ### $an
    $an->mark($win);
    push @anno_datas, $an;
}
if (!@anno_datas) {
    die "No this host's marked data";
}
my $inductor = new Markit::Wrapper::Inductor;
my $wrapper = $inductor->induct($pattern, \@anno_datas);
$wrapper->{host} = $host;
### $wrapper
#
my $wrapper_json = $json_xs->encode($wrapper);

my $pkey = $host . $pat_name;
my $cols = { "host" => $host, "pattern" => $pat_name, "type" => "wrapper", "wrapper" => $wrapper_json };

if(!$tdb->put($pkey, $cols)){
    my $ecode = $tdb->ecode();
    printf STDERR ("put error: %s\n", $tdb->errmsg($ecode));
}

# close the database
if(!$tdb->close()){
    my $ecode = $tdb->ecode();
    printf STDERR ("close error: %s\n", $tdb->errmsg($ecode));
}


