package Markit::FindAlg::Repeat;

use strict;
use warnings;

use VDOM::Node;
use List::Util qw( first );

use base 'Markit::FindAlg::Base';

__PACKAGE__->register('repeat');

our $MinDepth = 2;
our $MinIsologs = 2;
our $MinDepthFilterRegex = qr/\+.*?\+/;
our $InlineTagRegex = qr{
    ^(?:
        BIU]|\d+|NOBR|A|CITE|(?:W|NO)?BR|FONT|SMALL|BIG|EM|
        STRONG|DFN|CODE|SAMP|KBD|VAR|CITE|BASEFONT|APPLET|P|
        MAP|AREA|TT|TRIKE|BIG|SUB|SUP|IMG
    )$
}x;

sub compute_seq ($);

sub set_min_depth {
    my ($class, $depth) = @_;
    $MinDepth = $depth;
    my $s = join '.*?', "\\+" x $depth;
    $MinDepthFilterRegex = qr/$s/;
}

sub mine_doc {
    my ($class, $doc) = @_;

    my $res = $class->mine_node($doc->body);
}

sub find_nodes {
    my ($class, $elem, $args) = @_;

    my $res = $class->mine_node($elem);
    GROUP: for my $g (@$res) {
        next if !$g;
        for my $e (@$g) {
            next if !$e;
            if ($args) {
                my $min_width = $args->{min_width};
                if ($min_width && $e->w < $min_width) {
                    next GROUP;
                }

                my $min_height = $args->{min_height};
                #warn $e->h;
                #warn $e->xpath;
                if ($min_height && $e->h < $min_height) {
                    next GROUP;
                }

                my $min_area = $args->{min_area};
                if ($min_area && $e->w * $e->h < $min_area) {
                    next GROUP;
                }
            }
        }

        return $g;
    }

    return [];
}

sub mine_node {
    my ($class, $elem, $args) = @_;

    if (!$elem) {
        return [];
    }

    my @child = $elem->childNodes;
    my @groups;
    my %seq2list;
    for my $child (@child) {
        next if $child->nodeType != $VDOM::Node::ELEMENT_NODE;
        my $seq = compute_seq($child);
        ### $seq
        next if !$seq || $seq !~ /$MinDepthFilterRegex/;

        if (exists $seq2list{$seq}) {
            push @{ $seq2list{$seq} }, $child;
        } else {
            $seq2list{$seq} = [$child];
        }
        my $group = first { $_->[0] eq $seq } @groups;
        if (!defined $group) {
            push @groups, [$seq, 1];  # the second component is a counter
        } else {
            $group->[1]++;  # increment the counter
        }
    }

    my @retvals;
    for my $group (@groups) {
        next if !defined $group;
        my $seq = $group->[0];
        my $list = $seq2list{$seq};
        if ($group->[1] >= $MinIsologs) {
            push @retvals, $list;
        } else {
            for my $item (@$list) {
                my $sublists = $class->mine_node($item);
                if (@$sublists) {
                    push @retvals, @$sublists;
                }
            }
        }
    }

    return \@retvals;
}

sub compute_seq ($) {
    my $elem = shift;
    #warn "[0] ref:", ref $elem, "\n";
    return '' if $elem->nodeType != $VDOM::Node::ELEMENT_NODE;

    my $seq;
    # try to read the seq from the cache first:
    if ($seq = $elem->__seq) {
        return $seq;
    }
    my $tag = $elem->tagName;
    if ($tag =~ $InlineTagRegex) {
        $elem->__seq($seq);
        return '';
    }
    my $tag_code = bytes::chr( tag2char($tag) );
    $seq = '+' . $tag_code;
    for my $child ($elem->childNodes) {
        $seq .= compute_seq($child);
    }
    $seq .= '-' . $tag_code;
    $elem->__seq($seq);
    return $seq;
}


my %tag2char;
my $max_tag_char = 0;

sub tag2char {
    my $tag = shift;
    if (!exists $tag2char{$tag}) {
        my $code = ++$max_tag_char;
        while ($code == ord('+') || $code == ord('-') || $code == ord("\n")) {
            $code = ++$max_tag_char;
        }
        if ($code > 127) {
            warn "WARNING: tag count exceeds 127.\n";
            $max_tag_char = 0;
            $code = 1;
        }
        return ($tag2char{$tag} = $code);
    }
    return $tag2char{$tag};
}

sub seq2ascii {
    my $seq = shift;
    my %char2tag = reverse %tag2char;
    ##seq %char2tag
    $seq =~ s{([-+])(.)}{ $1 . $char2tag{bytes::ord($2)} }ge;
    ##seq seq2ascii: $seq
    $seq;
}

sub ascii2seq {
    my $ascii = shift;
    $ascii =~ s{([-+])(\w+)}{ $1 . chr(tag2char($2)) }ge;
    ##seq ascii2seq: $ascii
    $ascii;
}

1
