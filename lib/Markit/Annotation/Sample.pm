package Markit::Annotation::Sample; 

use strict;
use warnings;

use Class::XSAccessor
	getters => {
		get_url => 'url',
		get_vdom => 'vdom',
		get_patterns => 'patterns'
	};

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	my %args = @_;                                                                                                   
    die "Need specify 'url' parameter when constructing $class." unless($args{url});

	my $self = bless {                                                                              
		url => $args{url},
		vdom => ,
		patterns => {}
		}, $class; 

	$self;
}

sub has_pattern() {
	my $self = shift;
	return (defined $self->{patterns}) && (keys %{$self->{patterns}}) > 0;
}

sub set_vdom_data($) {
	my ($self,$vdom_data) = @_;
	$vdom_data = "" unless(defined $vdom_data) ;

	$self->{vdom_data} = $vdom_data;
}

sub set_pattern($) {
	my ($self,$pattern) = @_;

	$self->{patterns}->{$pattern->get_name} = $pattern_name;
}

1;

__END__

{
	url: "http://bbs.55bbs.com/thread-2888225-1-1.html",
	vdom_data: "",
	patterns: {
		"{Name of Markit::Pattern}": {Markit::Pattern}
		...
	}
}
