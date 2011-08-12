#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../xhunter/perl/VDOM/lib";
use lib "$FindBin::Bin/../lib";

use JSON::XS;
use File::Slurp;
use File::Spec::Functions;
use Params::Util qw(_HASH _STRING _ARRAY0 _ARRAY _SCALAR);

use Getopt::Long;
use Smart::Comments::JSON '###';

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

my $vdom_file = shift or
    die "Usage: $0 <infile>\n";
open my $in, $vdom_file or
    die "Can't open $vdom_file for reading: $!\n";
my $win = VDOM::Window->new->parse_file($in);
close $in;

my $doc = $win->document;
my $url = $win->location;
my $extractor = new Markit::Wrapper::Extractor;

my @wrapper_list;

my $wrapper_file =  catfile($pattern_dir, $pattern_name . "-" . $host . ".wrapper");
my $wrapper_json = read_file($wrapper_file);
    ### $wrapper_json
eval {
    my $wrapper_data = $json_xs->decode($wrapper_json);
    my $wrapper = Markit::Pattern::build($pattern_name, $wrapper_data);

    push @wrapper_list, $wrapper;
};


my $result;
$result =$extractor->extract(\@wrapper_list, $doc);

while (my ($attr, $val) = each (%$result)) {
    if (_HASH($val)) {
        #$val->{text} = $val->{node}->textContent;
        #delete $val->{node};
        $result->{$attr} = $val->{_node}->textContent;

    } elsif (_ARRAY($val)) {
        $result->{$attr} = join ' ', (map {$_->{_node}->textContent} @$val);
        #for my $v (@$val) {
        #    $v->{text} = $v->{node}->textContent;
        #    delete $v->{node};
        #}
    }
}

### $result

__END__
my $title_node = $result->{title}->{node};
my $title;
my $point = {
    x => 0,
    y => 0,
};
if ($title_node) {
    $point->{x} = $title_node->x;
    $point->{y} = $title_node->y;
    $title = $title_node->textContent;
    $title =~ s/^\s+|\s+$//gs;
    $title =~ s/\s+/ /gs;
}

my $summary = "URL: $url\n";
$summary .= "Title: $title\n";

my @items;
if ($title_node) {
    my $cand = $title_node;
    push @items, {
        x => $cand->x,
        y => $cand->y,
        w => $cand->w,
        h => $cand->h,
        borderColor => 'red',
        #noHighlight => $JSON::XS::true,
        desc => "Tag name: " . $cand->tagName . "\n" .
        $title . "\n",
        title => "Marktit Title Extraction",
    };
}



my @groups;
push @groups, \@items;
my $annotate_res = {
    jump_to => $point,
    summary => $summary,
    groups => \@groups,
    program => "Title Hunter $Markit::VERSION",
    #record_lists => $record_lists,
};

warn $summary;

my $outfile = $vdom_file . '.res';
open my $out, ">:encoding(utf8)", $outfile or
    die "Cannot open $outfile for writing: $!\n";
print $out $json_xs->encode($annotate_res);
close $out;

