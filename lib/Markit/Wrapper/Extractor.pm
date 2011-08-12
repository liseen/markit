package Markit::Wrapper::Extractor;

use strict;
use warnings;
use utf8;
#use Smart::Comments '###';
#use Smart::Comments::JSON '###d';
#use Smart::Comments::JSON '###ups';
use Clone qw(clone);
#use Data::Dumper;
#use Smart::Comments::JSON '###e';
#use VDOM;
use Time::Local;
use Params::Util qw(_HASH _STRING _NUMBER _ARRAY _SCALAR);
use List::MoreUtils qw(uniq);

use Markit::FindAlg::Repeat;
use Markit::FindAlg::Filter;

use Markit::Wrapper;
use Markit::Wrapper::Util qw(
    url2host
    get_pattern_by_path
);

our $NeedToUNIXTime = 1;
our $MarkDebug = 0;

sub get_same_parent {
     my ($self, $doc, $first, $last) = @_;

     if (!$first || !$last || $first == $doc || $last == $doc) {
        return undef;
     } elsif ($first == $last) {
         return $first;
     } else {
         return $self->get_same_parent($first->ownerDocument,
                                       $first->parentNode, $last->parentNode);
     }
}

sub new {
    my $class = ref $_[0] ? ref shift : shift;

    bless {
    }, $class;
};
my $result = {};
sub extract {
    my ($self, $wrapper_list, $page_doc) = @_;
    ###e extract...
    my $reason = '';
    my $i = 0;
    for my $wrapper (@$wrapper_list) {
        $i++;
        my %result;
        eval {
            $self->apply_wrapper(\%result, $page_doc->body, $wrapper);
            ###e extract after...
            if (exists $wrapper->{data}) {
                $result{data} = $wrapper->{data};
            }
        };
        if ($@) {
            $reason .= "wrapper $i: $@\n";
            next;
        }

        return \%result;
    }

    if ($reason) {
        die "$reason";
    }

    return undef;
}

sub apply_wrapper {
    my ($self, $result, $parent_pattern_node, $pattern) = @_;

    my $name = $pattern->name;
    ###d $name
    if (!$name) {
        ###e no name...
        $self->apply_sub_pattern($result, $parent_pattern_node, $pattern);
    } else {
        ###e $name
        my $type = $pattern->type;
        my $occur_type = $pattern->occur_type;
        my $data_type = $pattern->data_type;

        my $selector = $pattern->selector;
        my $find_alg = $pattern->{find_alg};
        my $required = $pattern->required;
        ### $type
        ### $occur_type
        ### $selector

        my $filters = $pattern->{'filters'};
        my $conditions = $pattern->{'conditions'};


        my @elems;

        # if has selector, this wrapper is not a common wrapper
        if ($selector) {
            if (_STRING($selector)) {
                @elems = $parent_pattern_node->getElementsBySelector($selector);
            } elsif (_ARRAY($selector)) {
                for my $sel (@$selector) {
                    push @elems, $parent_pattern_node->getElementsBySelector($sel);
                }
            }
        } elsif ($find_alg) { # find alg
            my $alg = $find_alg->{alg};
            my $args = $find_alg->{args};
            my $alg_package = $Markit::FindAlg::Base::FindAlgs{$alg};
            if ($alg_package) {
                my $g = $alg_package->find_nodes($parent_pattern_node, $args);
                push @elems, @$g;
            } else {
                die "No find alg : $alg found!\n";
            }

            my $recall = $pattern->{recall};
            if ($recall && @elems > 0 && $recall eq 'selector') {
                my $f_sel = $elems[0]->selector($parent_pattern_node);
                my @recall_elems = $parent_pattern_node->getElementsBySelector( $f_sel);
                push @elems, @recall_elems;

                $f_sel =~ s/>FORM[^>]*//gs;
                $f_sel =~ s/\.\w+$//gs;

                @recall_elems = $parent_pattern_node->getElementsBySelector( $f_sel);
                push @elems, @recall_elems;
            }
        }

        @elems = sort { $a->y <=> $b->y } @elems;
        @elems = uniq @elems;

        ### before apply condtions
        my $elem_count = @elems;
        ###d $elem_count
        @elems = grep { $self->apply_conditions($_, $conditions, $parent_pattern_node) } @elems;
        ### after apply condtions

        my $nodes = [];

        if ($type eq 'node') {
            push @$nodes, @elems;
        } elsif ($type eq 'node_count') {
            my $extracted = @elems;

            if ($extracted) {
                my $parent = $elems[0]->parentNode;
                $parent->{"_extracted_$name"} = $extracted;
                push @$nodes, $parent;
            }
        } elsif ($type eq 'node_text_combine') {
            if (@elems) {
                my $extracted = join '  ', map {$_->textContent} @elems;
                if ($extracted) {
                    my $parent;
                    if(@elems > 1) {
                        $parent = $self->get_same_parent($elems[0]->ownerDocument, $elems[0], $elems[-1])
                                    || $elems[0]->parentNode;
                    } else {
                        $parent = $elems[0]->parentNode;
                    }

                    $parent->{"_extracted_$name"} = $extracted;
                    push @$nodes, $parent;
                }
            }
        } else {
            for my $elem (@elems) {
                my $extracted;

                my $node_text;
                if (!$type || $type eq 'text') {
                    if ($elem->tagName eq 'IMG') {
                        $node_text = $elem->src;
                    } elsif ($elem->tagName eq 'INPUT') {
                        $node_text = $elem->value;
                    } else {
                        $node_text = $elem->textContent;
                    }
                } else {
                    eval {
                        $node_text = $elem->$type;
                    };
                    if ($@) {
                        die "invalid type: $type\n";
                    }
                }

                if ($data_type) {
                    if ($data_type eq 'datetime') {
                        $extracted = $self->extract_datetime($node_text);
                    } elsif ($data_type eq 'number') {
                        if ($node_text =~ /(\d+(?:\.\d+)?)/s) {
                            $extracted = $1;
                        }
                    } elsif ($data_type) {
                        ###d $data_type
                        if ($node_text =~ /$data_type/gs) {
                            $extracted = $1;
                        }
                    } else {
                        die "doesn't support data type: $data_type\n";
                    }
                } else {
                    $extracted = $elem->textContent;
                }

                ### begin apply filter
                $extracted = $self->apply_filters($extracted, $filters);
                ### end apply filter

                if (defined $extracted) {
                    $elem->{"_extracted_$name"} = $extracted;
                    push @$nodes, $elem;
                }
            }
        }

        if (@$nodes < 1 && $required eq 'yes') {
            die "Pattern $name is requried!\n";
        }

        my $failed_nodes_cnt = 0;
        my $failed_reason = '';

        if (@$nodes) {
            my $ret;
            if ($occur_type eq $Markit::Pattern::OccurTypeMultiple) {
                for my $n (@$nodes) {
                    my $r = {_node => $n};
                    eval {
                        $self->apply_sub_pattern($r, $r->{_node}, $pattern);
                    };
                    if ($@) {
                        $failed_reason = $failed_reason . $@ . " ";
                        $failed_nodes_cnt++;
                    } else {
                        push @$ret, $r;
                    }
                }
            } else {
                my $r = {_node => $nodes->[-1]};
                eval {
                    $self->apply_sub_pattern($r, $r->{_node}, $pattern);
                };
                if ($@) {
                    $failed_reason = $failed_reason . $@ . " ";
                    $failed_nodes_cnt++;
                } else {
                    $ret = $r;
                }
            }
            $result->{$name} = $ret;
        }

        #@$nodes = grep {! exists $_->{__extracted_failed};} @$nodes;
        #my $failed_cnt = grep {exists $_->{__extracted_failed};} @$nodes;
        #if (@$nodes == $failed_cnt && $required eq 'yes') {
        #warn "$name  $failed_nodes_cnt";
        if ($required eq 'yes' && @$nodes == $failed_nodes_cnt) {
            die "$failed_reason and Pattern $name is requried!\n";
        }
    }
    return $result;
}

sub apply_sub_pattern {
    ###e apply sub pattern...
    my ($self, $result, $parent_node, $pattern) = @_;

    # a reference bug of perl?
    $pattern = clone($pattern);
    #Dumper($pattern);
    ####e $pattern
    my $sub_pats = $pattern->childPatterns;
    while ( my ($sub_name, $sub_pat) = each %$sub_pats) {
        next if !$sub_name;
        $self->apply_wrapper($result, $parent_node, $sub_pat);
    }
}

sub apply_filters {
    my ($self, $content, $filters) = @_;

    return $content if !$filters;

    if (_STRING($filters)) {
        $content =~ s/$filters//gs;
    } elsif (_ARRAY($filters)) {
        for my $filter (@$filters) {
            next if !$filter;
            $content =~ s/$filter//gs;
        }
    } else {
        die "invalid filters: $filters specified\n";
    }

    return $content;
}

sub apply_conditions {
    ### apply conditions
    my ($self, $elem, $conditions, $parent_pattern_node) = @_;

    for my $condition (@$conditions) {
        return 0 if ! $self->apply_condition($elem, $condition, $parent_pattern_node);
    }

    return 1;
}

sub apply_condition {
    ### apply condtion
    my ($self, $elem, $condition, $parent_pattern_node) = @_;

    my $attr = $condition->{attr} || $condition->{type};
    my $cond = $condition->{cond};
    my $right_value = $condition->{value};

    my $left_value;
    if ($attr eq 'area') {
        $left_value = $elem->w * $elem->h;
    } elsif ($attr =~ 'content_length') {
        $left_value = length($elem->textContent);
    } elsif ($attr =~ /(\w+)\.(\w+)/) {
        if ($1 eq 'pre') {
            my $prev = $elem->previousElementSibling;
            $left_value = $prev ? $prev->$2 : '';
        } else {
            die "don'nt supoort attr $2 for $1";
        }
    } elsif ($attr eq 'pre_text') {
        my $prev = $elem->previousElementSibling;
        $left_value = $prev ? $prev->textContent : '';
    } elsif ($attr eq 'content') {
        my $tagName = $elem->tagName;
        ###d $tagName
        if ($tagName eq 'IMG') {
            $left_value = $elem->src;
        } elsif ($tagName eq 'INPUT') {
            $left_value = $elem->value;
            ###d $left_value
        } else {
            $left_value = $elem->textContent;
        }
    } elsif ($attr eq 'rx' || $attr eq 'ry') {
        $left_value = $elem->$attr($parent_pattern_node);
    } else {
        eval {
            $left_value = $elem->$attr;
        };
        if ($@) {
            die "invalid condition type: $attr\n";
        }
    }

    #if ($cond eq '!~') {
        ###c $left_value
        ###c $cond
        ###c $right_value
    #}
    if ($cond eq '=' || $cond eq 'eq') {
        if (_NUMBER($right_value)) {
            return $left_value == $right_value;
        } elsif (_STRING($right_value)) {
            return $left_value eq $right_value;
        } else {
            die "the value $right_value of condtion $attr is not valid\n";
        }
    } elsif ($cond eq '!=' || $cond eq 'ne') {
        if (_NUMBER($right_value)) {
            return $left_value != $right_value;
        } elsif (_STRING($right_value)) {
            return $left_value ne $right_value;
        } else {
            die "the value $right_value of condtion $attr is not valid\n";
        }
    } elsif ($cond eq '>' || $cond eq 'ge') {
        ### cond eq > $cond
        if (_NUMBER($right_value)) {
            return $left_value > $right_value;
        } elsif (_STRING($right_value)) {
            return $left_value ge $right_value;
        } else {
            die "the value $right_value of condtion $attr is not valid\n";
        }
    } elsif ($cond eq '<' || $cond eq 'le') {
        if (_NUMBER($right_value)) {
            return $left_value < $right_value;
        } elsif (_STRING($right_value)) {
            return $left_value le $right_value;
        } else {
            die "the value $right_value of condtion $attr is not valid\n";
        }
    } elsif ($cond eq '<' || $cond eq 'le') {
        if (_NUMBER($right_value)) {
            return $left_value < $right_value;
        } elsif (_STRING($right_value)) {
            return $left_value le $right_value;
        } else {
            die "the value: $right_value of condtion is not valid\n";
        }
    } elsif ($cond eq '=~' || $cond eq 'like') {
        if (_STRING($right_value)) {
            return $left_value && $left_value =~ /$right_value/s;
        } else {
            die "the value: $right_value of condtion is not valid\n";
        }
    } elsif ($cond eq '!~' || $cond eq 'not like') {
        if (_NUMBER($right_value)) {
            die "the value of match type condition must be string\n";
        } elsif (_STRING($right_value)) {
            return $left_value && $left_value !~ /$right_value/s;
        } else {
            die "the value: $right_value of condtion is not valid\n";
        }

    } else {
        die "the cond : $cond of condtion is not valid\n";
    }
}


sub extract_datetime {
    my ($self, $txt) = @_;

    my ($y, $m, $d);
    if ($txt =~ /((?:19|20)?\d{2})\s*(?:年|－|-|\.)\s*(\d{1,2})\s*(?:月|－|-|\.)\s*(\d{1,2})\s*(?:日|号|.|\\s)?/) {
        ($y, $m, $d) = ($1, $2, $3);
        if (length($y) == 2) {
            if ($y =~ /^9/) {
                $y = '19' . $y;
            } elsif ($y =~ /^0/) {
                $y = '20' . $y;
            }
        }
    } elsif ($txt =~ /(\d+)\s*天前\s*/) {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time - $1 * 86400);
        ($y, $m, $d) = ($year + 1900, $mon + 1, $mday);
    } elsif ($txt =~ /前\s*天\s*(\d+):(\d+)/) {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time - 2 * 86400);
        ($y, $m, $d) = ($year + 1900, $mon + 1, $mday);
    } elsif ($txt =~ /昨\s*天\s*(\d+):(\d+)/) {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time - 1 * 86400);
        ($y, $m, $d) = ($year + 1900, $mon + 1, $mday);
    } elsif ($txt =~ /\d+小时前/) {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        ($y, $m, $d) = ($year + 1900, $mon + 1, $mday);
    }

    if ($y) {
        if ($NeedToUNIXTime) {
            my $time;
            eval {
                $time = timelocal(0, 0, 0, $d, $m -1, $y - 1900);
            };
            return $time;
        } else {
            return "$y-$m-$d";
        }
    }

    return undef;
}

1;
