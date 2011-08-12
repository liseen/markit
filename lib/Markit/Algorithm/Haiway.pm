package Markit::Algorithm::Haiway;

use strict;
use warnings;

use VDOM::Node;
use List::Util qw( first );

our $MinDepth = 2;
our $MinIsologs = 2;
our $MinDepthFilterRegex = qr/\+.*?\+/;
our $InlineTagRegex = qr{
    ^(?:
        BIU]|\d+|NOBR|A|(?:W|NO)?BR|FONT|SMALL|BIG|EM|
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
    ### $MinDepthFilterRegex

    my $res = $class->mine_node($doc->body);
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

    ##seq @groups

=begin cmt

    # merge similar groups using trigram:
    my @seqs = map { $_->[0] } @groups;
    #for my $seg (@segs) {
    #}
    $trigram->reInit(\@seqs);
    my %merged_seqs = ();
    my $i = 0;
    for my $seq (@seqs) {
        if ($merged_seqs{$seq}) {
            undef $groups[$i];
            next;
        }
        my %result;
        my $count = $trigram->getSimilarStrings($seq, \%result);
        if ($count > 1) {
            delete $result{$seq};
            while (my ($matched_seq, $similarity) = each %result) {
                if ($merged_seqs{$matched_seq}) {
                    #warn "HERE!";
                    last;
                }
                #next if $matched_seq eq $seq;
                warn "$similarity\n+ $matched_seq\n- $seq\n\n";
                $merged_seqs{$matched_seq} = 1;
                #$merged_seqs{$seq} = 1;
                my $matched_list = $seq2list{$matched_seq};
                #delete $seq2list{$matched_seq};
                #if ($seq2list{$seq} eq $matched_list) {
                #die "Failed!";
                #}
                push @{ $seq2list{$seq} }, @$matched_list;
                $groups[$i]->[1] += @$matched_list;
                last;
            }
        }
    } continue {
        $i++;
    }

=end cmt
=cut

    my @retvals;
    for my $group (@groups) {
        next if !defined $group;
        my $seq = $group->[0];
        #next if $merged_seqs{$seq};
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

=begin
sub compute_seq ($) {
    my $elem = shift;

    return '' if $elem->nodeType != $VDOM::Node::ELEMENT_NODE;

    my $seq;
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
        if ($child->w * $child->h > 20000) {
            $seq .= $child->w;
        }
    }
    $seq .= '-' . $tag_code;
    $elem->__seq($seq);

    return $seq;
}

=cut

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

1;
