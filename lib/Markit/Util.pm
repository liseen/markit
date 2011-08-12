package Markit::Util;

use warnings;
use strict;
#use utf8;

use Params::Util qw(_HASH _STRING _ARRAY0 _ARRAY _SCALAR);
use List::MoreUtils qw(uniq);

our @ColorRange = qw/Blue Brown BurlyWood Chartreuse Green MediumPurple  Olive Navy Chocolate Coral Cornsilk Crimson Cyan DarkCyan DarkGoldenRod DarkGray DarkGreen DarkKhaki DarkMagenta DarkOliveGreen Darkorange DarkOrchid DarkRed DarkSalmon DarkSeaGreen DarkSlateBlue DarkSlateGray DarkTurquoise DarkViolet DeepPink/;
our $color_index = 0;

sub url2domain {
    my $url = shift;
    my $host;
    if ($url =~ /https?:\/\/([^\/]+?)(?:\d+)?\//) {
        $host = $1;
    } else {
        return undef;
    }

    if ($host =~ /([\w-]+\.(?:com|org|net|org))(?:\.cn)$/) {
        return $1;
    } elsif ($host =~ /([\w-]+\.(?:com|org|net|org|cn))$/) {
        return $1;
    }

    return undef;
}

sub delete_node_info_for_result {
    my ($result, $name) = @_;
    _HASH($result) or die "Result should be hash!\n";

    if (exists($result->{_node})) {
        my $node = delete $result->{_node};

        if ($node && exists $node->{"_extracted_$name"}) {
            $result->{text} = $node->{"_extracted_$name"};
        }
    }

    while (my ($attr, $val) = each (%$result)) {
        next if $attr =~ /^_/;
        if (_HASH($val)) {
            delete_node_info_for_result($val, $attr);
        } elsif (_ARRAY($val)) {
            for my $v (@$val) {
                delete_node_info_for_result($v, $attr);
            }
        }
    }
}

sub get_next_color {
    if ($color_index >= @ColorRange) {
        $color_index = 0;
    }
    return $ColorRange[$color_index++];
}

sub gen_groups_for_result {
    no warnings 'uninitialized';
    my ($groups, $result, $name, $color) = @_;

    _HASH($result) or die "Result should be hash!\n";

    while (my ($attr, $val) = each (%$result)) {
        next if $attr =~ /^_/;
        if (_HASH($val)) {
            my @reg;
            my $i = 1;
            my $node = $val->{_node};
            next if !$node;
            push @reg, {
                x => $node->x,
                y => $node->y,
                w => $node->w,
                h => $node->h,
                borderColor => $color || 'red',
                desc => $node->w . 'x' . $node->h . '@(' . $node->x . ',' . $node->y . ")\n\n" . "ID: " . $i++ . "\n" . "Text: " . $node->{"_extracted_$name"} . "\n",
                title => 'Found ' . " $attr",
            };

            push @$groups, \@reg;

            gen_groups_for_result($groups, $val, $attr);
        } elsif (_ARRAY($val)) {
            # push all nodes
            my @reg;
            my $i = 1;
            for my $v (@$val) {
                my $node = $v->{_node};
                push @reg, {
                    x => $node->x,
                    y => $node->y,
                    w => $node->w,
                    h => $node->h,
                    borderColor => 'red',
                    desc => $node->w . 'x' . $node->h . '@(' . $node->x . ',' . $node->y . ")\n\n" . "ID: " . $i++ . "\n" . "Text: " . $node->{"_extracted_$name"} . "\n",
                    title => 'Found ' . scalar(@$val) . " $attr" . 's',
                };

                push @$groups, \@reg;
            }

=begin
            my @fields;
            for my $v (@$val) {
                push @fields, grep { /^[^_]/ } keys %$v;
            }

            @fields = uniq @fields;
            @fields = sort @fields;
            for my $fields (@fields) {
                my @field_reg;
                my $color = get_next_color;
                $i = 1;
                for my $v (@$val) {
                    my $node = $v->{$fields}->{_node};
                    next if !$node;
                    push @field_reg, {
                        x => $node->x,
                        y => $node->y,
                        w => $node->w,
                        h => $node->h,
                        borderColor => $color,
                        desc => $node->w . 'x' . $node->h . '@(' . $node->x . ',' . $node->y . ")\n\n" . "ID: " . $i++ . "\n". "Pattern: " . $fields . "\nText: " . $node->{"_extracted_$fields"} . "\n",

                        title => 'Found ' . scalar(@$val) . " $fields" . 's',
                    }
                };

                push @$groups, \@field_reg;
            }
=cut
for my $v (@$val) {
    my $color = get_next_color;
    gen_groups_for_result($groups, $v, $attr, $color);
}
}
}
}

1;

