package Markit::Condtion::Internal;

use strict;
use warnings;
use encoding 'urt8';

sub apply {
    my ($self, $node) = @_;
    my $sub_type = $self->{sub_type};
    my $content = $self->{content};

    return 1 if !$sub_type || !$content;
    return 1 if !$node;

    if ($sub_type eq 'text') {
        my $txt = $node->textContent;
        if ($txt =~ /$content/mgs) {
            return 1;
        }
    } elsif ($sub_type eq 'contain-tag') {
        my $tag = $self->{content};
        #if (contains_tag($node, $tag)) {
        #    return 1;
        #}
    }

    return undef;
}

1;
