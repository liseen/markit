package Markit::Filter;

sub new {
    my $class = ref $_[0] ? ref shift : shift;

    bless {
        conditions => []
    }, $class;
};

sub add_condition {
    my $self = shift;
    my $conditon = shift;

    push @{$self->{conditions}}, $conditon;
}

sub conditions {
    my $self = shift;
    return $self->{conditions};
}

sub TO_JSON {
    my $self = shift;
    return {conditons => $self->conditions};
}
1;
