package Markit::App::OutputFilter;

use strict;
use warnings;

use Markit;

sub comment_output {
    my ($self, $url, $win, $result) = @_;
    ### $result
    no warnings 'uninitialized';

    my $page_title = $win->document->title;

    my $rating_base = $result->{data}->{rating_base};

    my $default_product = $result->{product_name}->{text};

    my $recs = [];
    my $commends = $result->{comment};
    for my $cm (@$commends) {
        my $rec = [];
        push @$rec, $url;

        push @$rec, $cm->{author}->{text};
        push @$rec, $cm->{title}->{text};
        push @$rec, $cm->{pub_time}->{text};
        push @$rec, $cm->{strong_point}->{text};
        push @$rec, $cm->{weak_point}->{text};
        push @$rec, $cm->{summary}->{text};

        if ($rating_base) {
            my $rating = $cm->{rating}->{text};
            if ($rating) {
                $rating = $rating / $rating_base * 5;
            }
            push @$rec, $rating;
        } else {
            push @$rec, $cm->{rating}->{text};
        }

        push @$rec, $cm->{thumb_ups}->{text};

        if (exists $cm->{thumb_downs}->{text}) {
            push @$rec, $cm->{thumb_downs}->{text};
        } else {
            my $thumb_totals = $cm->{thumb_totals}->{text} || 0;

            my $thumb_downs = 0;
            if ($thumb_totals) {
                my $thumb_ups =  $cm->{thumb_ups}->{text} || 0;
                $thumb_downs = $thumb_totals - $thumb_ups;
            }

            push @$rec, $thumb_downs;
        }

        if (exists $cm->{product_name}{text}) {
            push @$rec, $cm->{product_name}->{text};
        } elsif ($default_product) {
            push @$rec, $default_product;
        } else {
            push @$rec, $page_title;
        }

        for my $r (@$rec) {
            $r =~ s/[\t\n]/ /gs if $r;
        }

        push @$recs, $rec;
    }

    return $recs;
}

sub qa_output {
    my ($self, $url, $win, $result) = @_;

    no warnings 'uninitialized';

    my $rec = [];
    push @$rec, $url;
    push @$rec, $result->{question}->{text} || '';
    push @$rec, $result->{description}->{text} || '';
    push @$rec, $result->{pub_time}->{text} || '';
    push @$rec, join "\002\002", (map {$_->{text}} @{$result->{best_answers}});
    push @$rec, join "\002\002", (map {$_->{text}} @{$result->{other_answers}});

    for my $r (@$rec) {
        $r =~ s/[\t\n]/ /gs if $r;
    }

    return [$rec];
}

sub bbs_output_filter {
    my ($self, $url, $win, $result) = @_;

    no warnings 'uninitialized';

    if ($result) {
        my $page_title = $win->document->title;

        my $title;
        if (! exists $result->{title}->{text}) {
            my @ts = split /[_,|]+/, $page_title;
            for my $t (@ts) {
                next if !$t;
                $t =~ s/^\s+//s;
                $t =~ s/\s+$//s;
                next if !$t;
                next if $t =~ /论坛\w?$/;
                next if $t =~ /^\W+\w+\.\w+\.\w+\W+$/;

                $title = $t;
                last;
            }

            $result->{title}->{text} = $title;
        }
    }

    return $result;
}

1;
