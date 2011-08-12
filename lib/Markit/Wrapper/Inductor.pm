package Markit::Wrapper::Inductor;

use strict;
use warnings;

use Smart::Comments '###';
use VDOM;
use Markit::Wrapper;
use Markit::Wrapper::Util qw(
    url2host
    get_pattern_by_path
    get_parent_by_path
    get_xpath_by_path
    get_parent_xpath_by_path
);

use Markit::Filter;
use Markit::Condition;

sub new {
    my $class = ref $_[0] ? ref shift : shift;

    bless {
    }, $class;
};


sub induct {
    my ($self, $pattern_root, $anno_datas) = @_;

    my $wrapper = $pattern_root;
    eval {
        $self->induct_wrapper($anno_datas, $wrapper);
    };
    if ($@) {
        warn "$@\n";
        return undef;
    }
    return $wrapper;
}

sub induct_wrapper {
    my ($self, $an_patterns, $wrapper_pattern) = @_;
    my $pattern = $wrapper_pattern;

    my $name = $pattern->name;
    if ($name) {
        #induct self
        my $type = $pattern->type;
        my $occur_type = $pattern->occur_type;

        my $selector;
        my $conditions = [];

        for my $an (@$an_patterns) {
            my $node = $an->{node};
            #warn "get node: ".$node->textContent;
            if (!defined $selector) {
                $selector = $node->selector;
            } elsif ($selector ne $node->selector) {
                die "selector is different\n";
            }
        }

        $pattern->{selector} = $selector;
        $pattern->{conditions} = $conditions;
    }

    # induct sub patterns
    my $sub_pats = $wrapper_pattern->childPatterns;
    while ( my ($sub_name, $sub_pat) = each %$sub_pats) {
       my @sub_an_pats;
       for my $an (@$an_patterns) {
            push @sub_an_pats, $an->childPatterns->{$sub_name};
       }
       $self->induct_wrapper(\@sub_an_pats, $sub_pat);
    }
}

1;
