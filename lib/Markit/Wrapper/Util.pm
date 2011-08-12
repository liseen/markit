package Markit::Wrapper::Util;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw(
    url2host
    get_pattern_by_path
    get_parent_by_path
    get_xpath_by_path
    get_parent_xpath_by_path
);

sub url2host {
    my $url = shift;
    if ($url =~ /^https?:\/\/([^\/]*)/) {
        return $1;
    }
    return undef;
}


sub get_parent_by_path {
    my ($pattern, $path) = @_;

    if ($path =~ s/\.\w+$//) {
        return get_pattern_by_path($path);
    }
    return undef;
}

sub get_parent_xpath_by_path {
    my ($pattern, $path) = @_;

    if ($path =~ s/\.\w+$//) {
        return get_xpath_by_path($path);
    }
    return undef;
}

sub get_pattern_by_path {
    my ($pattern, $path) = @_;

    return undef if !$path;
    my @levels = split /\./, $path;
    for my $level (@levels) {
        my $patterns = $pattern->childPatterns;
        return undef if !$patterns;
        $pattern = $patterns->{$level};
        return undef if !$pattern;
    }
    return wantarray ? ($levels[-1], $pattern) : $pattern;
}

sub get_xpath_by_path {
    my ($pattern, $path) = @_;

    return undef if !$path;
    my $xpath = '';
    my @levels = split /\./, $path;
    for my $level (@levels) {
        my $patterns = $pattern->{patterns};
        return undef if !$patterns;
        $pattern = $patterns->{$level};
        return undef if !$pattern;
        my $rel_xpath = $pattern->{xpath};
        return undef if !$rel_xpath;
        $xpath .= $rel_xpath;
    }
    return $xpath;
}

1;
