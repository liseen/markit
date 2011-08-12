#!/usr/bin/env perl

use strict;
use warnings;

#use Smart::Comments;

use JSON::XS;
use Getopt::Long;
use Params::Util qw /_HASH _ARRAY/;
use Encode qw /encode/;
use LWP::UserAgent;

use FindBin;
use lib "$FindBin::Bin/../../xhunter/perl/VDOM/lib";
use lib "$FindBin::Bin/../lib";

use VDOM;
use Markit;

my $exit_code = 0;
$Markit::Wrapper::Extractor::NeedToUNIXTime = 0;

use Markit::App::OutputFilter::BBS;

my $json_xs = JSON::XS->new->relaxed->pretty->allow_blessed->convert_blessed;
my $ua = LWP::UserAgent->new;

my $app;
my $vdom_url = "http://127.0.0.1:1986/vdomdump";
my $wrapper_dir = "$FindBin::Bin/../wrappers";

GetOptions("wrapper-dir=s"  => \$wrapper_dir,
           "app=s"  => \$app,
       );

my $app_extractor = new Markit::App::Extractor($wrapper_dir);

if (!$app) {
    for my $detect_app (keys %Markit::App::Extractor::WrapperCache) {
	### $detect_app...
	detect_app($detect_app);
    }
} else {
    my $detect_app = $app;
    detect_app($detect_app);
}

exit $exit_code;

sub detect_app {
    my ($app) = @_;
    my $domains =  $Markit::App::Extractor::WrapperCache{$app};
    while (my ($domain, $wrappers) = (each %$domains)) {
        for my $wrapper (@$wrappers) {
            detect_wrapper($app, $domain, $wrapper);
        }
    }
}

sub detect_wrapper {
    my ($app, $domain, $wrapper) = @_;
    my $sample_urls = $wrapper->{samples};
    for my $url (@$sample_urls) {

	eval {
            ### detect app $app, domain $domain, url $url...
            my $win = get_vdom($url);
            my $result;
            eval {
                $result = $app_extractor->extract($app, $url, $win);
            };
            if ($@) {
                die "Failed extract, reason: $@";
            }
            sleep 5;
        };
        if ($@) {
            $exit_code = $exit_code + 1;
            log_it("fail: detect app $app, domain $domain, url $url, reason $@\n")
        } else {
            log_it("succ: detect app $app, domain $domain, url $url\n")
        }
    }
}

sub log_it (@) {
    my $now = localtime;
    my $s = shift;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
    $year += 1900; $mon += 1;
    $s =~ s/\n+//gs;
    chomp($s);
    warn sprintf("[%04d-%02d-%02d %02d:%02d:%02d] %s\n", $year, $mon, $mday, $hour, $min, $sec, $s);
}

sub get_vdom {
    my ($url) = @_;

    my $raw_data = get_raw_data($url);
    if (!$raw_data) {
        die "Cannot get raw data";
    }
    $raw_data = encode("utf8", $raw_data);
    # get vdom
    my $req = HTTP::Request->new(POST => $vdom_url);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($url . "\n" . $raw_data);

    my $vdom;
    my $res = $ua->request($req);
    if ($res->is_success) {
        $vdom = $res->content;
    } else {
        die "cannot get vdom for url: $url, reason: " . $res->status_line . "\n"
    }

    my $win;
    eval {
        $win = VDOM::Window->new->parse(\$vdom);
    };
    if ($@) {
        die "invalid vdom, reason: $@";
    }

    return $win;
}

sub get_raw_data {
    my $url = shift;

    my $response = $ua->get($url);

    if ($response->is_success) {
        return $response->decoded_content;  # or whatever
    } else {
       die "get raw data failed:  $response->status_line";
    }
}






