#!/usr/bin/env perl

use strict;
use warnings;
#use utf8;
#use encoding 'utf8';

use FindBin;
use lib "$FindBin::Bin/../../../../scripts/";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../vdompm/lib";

use Markit;
$Markit::Wrapper::Extractor::NeedToUNIXTime = 0;

use ProcCtl;

my $wrapper_dir = "$FindBin::Bin/../wrappers/";
my $app = "comment";
#my $app = "qa";

use Getopt::Long;

GetOptions( "app=s"  => \$app);

sub extract_work {
    my $arg = shift or
        die "file prefix and base doc id not specified\n";
    my $file_prefix = $arg->{file_prefix};
    my $base_id = $arg->{base_id} || 0;

    my $app_extractor = new Markit::App::Extractor($wrapper_dir);
    my $batch_vdom_file = $file_prefix . "_vdomdump";
    my $output_file = $file_prefix . "_$app";

    open my $in, $batch_vdom_file or
        die "Can't open $batch_vdom_file for reading: $!\n";

    open my $out, ">:encoding(utf8)", $output_file or
        die "Can't open $output_file for reading: $!\n";

    my $cm_id = $base_id;
    while (<$in>) {
        chomp;
        my ($rabin_hash, $url, undef, $vdom, $pid) = split /\t/;
        if (!$vdom) {
            warn "cannot get vdom from input line.\n";
            next;
        }

        $vdom =~ s/\001/\n/gs;

        my $win;
        eval {
            $win = VDOM::Window->new->parse(\$vdom);
        };
        if ($@) {
            warn "invalid vdom, reason: $@";
            next;
        }

        my $result;
        eval {
            $result = $app_extractor->extract($app, $url, $win);
        };
        if ($@) {
            #if ($@ !~ /(?:comment|question)/) {
               warn "Failed extract $url, reason: $@\n";
            #}
        } elsif (keys %$result > 0) {
            Markit::Util::delete_node_info_for_result($result);
            my $output_method = $app . "_output";
            my $records = [];
            eval {
                $records = Markit::App::OutputFilter->$output_method($url, $win, $result);
            };
            if ($@) {
                die "No output filter for app: $app reason: $@\n";
            }

            for my $rec (@$records) {
                no warnings 'uninitialized';
                my $r = join "\t", @$rec;

                if ($app eq 'comment') {
                    if ($pid) {
                        print $out "$cm_id\t$r\t$pid\n";
                    } else {
                        print $out "$cm_id\t$r\n";
                    }
                } elsif ($app eq 'qa') {
                    print $out "$rabin_hash\t$r\n";
                } else {
                    die "No supported app: $app\n";
                }

                $cm_id++;
                #print $out "$doc_id\t$url\t$r\n";
            }
        } else {
            #warn "Cannot  extract $url\n";
        }
    }

    close($in);
    close($out);
}

my $file_names = shift
    or die "No file names specified!\nUsage: $0 -app=<qa|comment> <file_names> <base_doc_ids>\n";

my $base_doc_ids = shift;

if ($app eq 'comment' && !defined $base_doc_ids) {
     die "No base doc id specified!\nUsage: $0 -app=<qa|comment> <file_names> <base_doc_ids>\n";
}

my @files = split /:/, $file_names;

my @base_ids;

if (defined $base_doc_ids) {
    @base_ids = split /:/, $base_doc_ids;
    if (scalar(@base_ids) < scalar(@files)) {
        die "The count of base id need more than file count\n";
    };
}

ProcCtl::Init(scalar @files);

for my $i (0..$#files) {
    my $arg = { file_prefix => $files[$i] };

    if (defined $base_doc_ids) {
        $arg->{base_id} = $base_ids[$i];
    }

    ProcCtl::Fork(\&extract_work, $arg);
}

ProcCtl::Wait();


