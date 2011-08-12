#!/usr/bin/env perl

use strict;
use warnings;
use Encode qw /_utf8_on/;
use encoding 'utf8';
use utf8;

#use Smart::Comments '###';
use FindBin;
use JSON::XS;
use Getopt::Long;
use VDOM;

use lib "$FindBin::Bin/../lib";

use Markit;
#use Test::More 'no_plan';

my $verbose = 0;
my $count = 0;
my $alg;

GetOptions("verbose|v"  => sub { $verbose++; },
            "count|c" => sub { $count++; },
           "list|l"  => \$alg
        );

my $find_txt;
if (!$alg) {
    $find_txt = shift or
        die "Usage: $0 -v --list <text|selector> vdom_file\n";
}

my $vdom_file = shift || "tmp/vdom";

open my $in, $vdom_file or
    die "Can't open $vdom_file for reading: $!\n";
my $win = VDOM::Window->new->parse_file($in);
close $in;

_utf8_on($find_txt);

my $doc = $win->document;
if ($alg) {
    my $all_lists = Markit::Algorithm::Haiway->mine_doc( $doc );

    my @comment_lists = grep {grep_comment_list($_)} @$all_lists;
    for my $list (@comment_lists) {
        warn "get comment list: size(" . @$list . ") " . $list->[0]->selector . "\n";
    }
}
elsif ($find_txt =~ /^BODY/ ) {
    my $selector = $find_txt;
    my $body = $doc->body;

    my @elems = $body->getElementsBySelector($selector);

    print "Get node count: " . scalar @elems . " Width: " . $elems[0]->w . "\n";
    if ($count) {
        exit 0;
    }

    if (@elems) {
        for my $e (@elems) {
            print "=" x 20;
            my $t = $e->textContent;
            $t =~ s/\t+/\n/gs;
            $t =~ s/[ \t\r]+/ /gs;
            $t =~ s/\s*\n+\s*/\n/gs;

            print "\n" . $t . "\n";
            my @nodes = get_text_nodes($e);
            for my $node (@nodes) {
                print_text_node($node, $e);
            }

            for my $img (get_img_nodes($e)) {
                next if !$img;
                print_img_node($img, $e);
            }

            last if $verbose < 2;
        }
    }
} else {
    my @nodes = get_text_nodes($doc);
    for my $node (@nodes) {
        my $txt = $node->textContent;
        if ($txt =~ /$find_txt/gs) {
            print_text_node($node);
        }
    }
}

sub print_text_node {
    my $node = shift;
    my $base_node = shift;

    my $txt = $node->textContent;
    my $tmp = $txt;
    $tmp =~ s/\s//gs;

    return if ! length($tmp);

    print "\n==" . substr($txt, 0, 50) . "\n";

    my $p = $node->parentNode;
    print $p->selector($base_node) . "\n";
    print $p->asVdom . "\n" if $verbose;
}

sub get_text_nodes {
    my $node = shift;
    if ($node->nodeType == $VDOM::Node::TEXT_NODE) {
        return $node;
    } else {
        my @ret;
        for my $child ($node->childNodes) {
            push @ret, get_text_nodes($child);
        }
        return @ret;
    }
}

sub print_img_node {
    my $node = shift;
    my $base_node = shift;

    my $txt = $node->src;
    print "\n==" . $txt . "\n";
    print $node->selector($base_node) . "\n";
}

sub get_img_nodes {
    my $node = shift;

    if ($node->nodeType == $VDOM::Node::TEXT_NODE) {
        return undef;
    } elsif ($node->tagName eq 'IMG') {
        return $node;
    } else {
        my @ret;
        for my $child ($node->childNodes) {
            push @ret, get_img_nodes($child);
        }
        return @ret;
    }
}

sub grep_comment_list {
    my $list = shift;

    return 0 if !$list;

    for my $item (@$list) {
        return 0 if !$item;
        return 0 if $item->w < 500;
        return 0 if $item->h < 100;
    }

    return 1;
}
