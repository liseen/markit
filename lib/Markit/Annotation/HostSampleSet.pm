package Markit::Annotation::HostSampleSet;

use strict;
use warnings;

use POSIX;
use URI;

use Class::XSAccessor
	getters => {
		get_hostname => 'hostname'
	},
    accessors => {
        wrappers => 'wrappers',
        samples => 'samples',
        sample2wrapper => 'sample2wrapper',
        wrapper2sample => 'wrapper2sample',
	};

sub new {
    my $class = ref $_[0] ? ref shift : shift;

	my %args = @_;
	die "Need specify 'hostname' parameter when constructing $class." unless($args{hostname});

    my $self = bless {
    }, $class;

	$self->{hostname} = $args{hostname};
	$self->{wrappers} = undef;
	$self->{samples} = undef;
	$self->{sample2wrapper} = undef;
	$self->{wrapper2sample} = undef;

    $self;
}

sub has_samples() {
	my $self = shift;
	return (defined $self->{samples}) && (keys %{$self->{samples}}) > 0;
}

sub add_sample($$) {
	my ($sample,$wrapper) = @_;
		
}

sub del_sample($) {
}

sub get_wrapper($) {
}


1;

__END__

{	
	hostname: "bbs.55bbs.com",
	wrappers: {
		"wrapper1":	{wrapper object}
	},
	samples: {
		"http://bbs.55bbs.com/thread-2888225-1-1.html": {sample object}
	},
	s2w: {
		"http://bbs.55bbs.com/thread-2888225-1-1.html":	"wrapper1"
	},
	w2s: {
		"wrapper1": "http://bbs.55bbs.com/thread-2888225-1-1.html"
	}
}
