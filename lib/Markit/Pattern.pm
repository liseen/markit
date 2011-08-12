package Markit::Pattern;

#use strict;
use warnings;
#use Smart::Comments;

use Markit::Pattern::Content;

#constant
=begin
use constant OccurTypeSingle => 'single';
use constant OccurTypeMultiple => 'multiple';

use constant RequiredYes => 'yes';
use constant RequiredNo => 'no';

use constant NodeType => 'node';
use constant TextType => 'text';
=cut

our $OccurTypeSingle = 'single';
our $OccurTypeMultiple = 'multiple';
our $RequiredYes = 'yes';
our $RequiredNo = 'no';

our $NodeType = 'node';
our $TextType = 'text';


#members
use Class::XSAccessor
    accessors => {
        name => 'name',
        type => 'type',
        data_type => 'data_type',
        content => 'content',
        occur_type => 'occur_type',
        required => 'required',
        selector => 'selector',
        filter => 'filter',
    #     purificant => 'purificant',
        childPatterns => '_childPatterns',
        parentPattern => '_parentPattern'
    },

    predicates => {
        has_content => 'content',
        has_selector => 'selector',
        has_filter => 'filter',
        has_purificant => 'purificant',
        has_childPatterns => '_childPatterns',
        has_parentPattern => '_parentPattern'
    };


sub new {
	my $class = ref $_[0] ? ref shift : shift;

	my %args = @_;
        #die "Need specify 'name' parameter when constructing $class." unless($args{name});

	my $self = bless {
		name => $args{name},
		content => undef,
                type => 'text',
		occur_type => 'single',
		required => $RequiredNo,
		selector => undef,
#		filter => undef,
#		purificant =>undef,
		_childPatterns => undef,	
		_parentPattern => undef
	}, $class;

	$self;
}

##!!!! NOTE: This is a static method
sub build {	
    my ($name, $hash) = @_;

    ### $name
    ### $hash
    my $self = Markit::Pattern->new(name => $name);

    while (my ($attr, $val) = each %$hash) {
        next if $attr =~  /^_/;

        $self->{$attr} = $val;
    }

    my %sub_patterns;
    my $patterns = $hash->{childPatterns} || {};
    while (my ($sub_name, $sub_pat_hash) = each %$patterns) {
        my $sub_pat = build($sub_name, $sub_pat_hash);
        $sub_patterns{$sub_name} = $sub_pat;
    }
    $self->{_childPatterns} = \%sub_patterns;

    $self;
}

=begin
sub childPatterns {
    my $self = shift;
    if (@_) {
        $self->{_childPatterns} = $_;
    } else {
        my $val = $self->{_childPatterns};
        return $val ? $val : {};
    }
}

sub parentPattern {
    my $self = shift;

    if (@_) {
        $self->{_parentPattern} = $_;
    } else {
        return $self->{_parentPattern};
    }
}

=cut

sub rootPattern {
    my $self = shift;

    my $root = $self;
    my $parent = $self->parentPattern;

    while ($parent) {
        $root = $parent;
        $parent = $parent->parentPattern;
    }
    return $root;
}

sub mark {
    my ($self, $win, $parent_node) = @_;

    if (!$parent_node) {
        $self->{node} = $win->document;
    } else {
        my $xpath = $self->xpath;
        #warn "marked xpath: $xpath";
        $self->{node} = $parent_node->getNodeByXpath($xpath);
    }

    my $sub_pats = $self->childPatterns;
    while ( my ($sub_name, $sub_pat) = each %$sub_pats) {
        $sub_pat->mark($win, $self->{node});
    }
}

sub TO_JSON {
    my ($self) = @_;
    my $hash = {};
    while (my ($key, $val) = each %$self) {
        next if $key =~ /^_/;
        next if $key =~ /^node|name$/;

       $hash->{$key} = $val;
    };

    $hash->{childPatterns} = $self->childPatterns;
    $hash;
}

1;
