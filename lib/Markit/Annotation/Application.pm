package Markit::Annotation::Application;

use strict;
use warnings;

use POSIX;
use URI;

use Class::XSAccessor
	getters => {
		get_name => 'name',
		get_samples => 'samples'
	},
    accessors => {
        creator => 'creator',
        create_date => 'create_date',
        last_revisor => 'last_revisor',
        last_revise_date => 'last_revise_date',
	};

sub new {
    my $class = ref $_[0] ? ref shift : shift;

	my %args = @_;
	die "Need specify 'name' parameter when constructing $class." unless($args{name});

    my $self = bless {
    }, $class;

	$self->{name} = $args{name};
	$self->{creator} = $args{creator} if (exists $args{creator});
	$self->{create_date} = strftime('%Y-%m-%d %H:%M:%S', localtime);
	$self->{last_revisor} = $self->{creator};
	$self->{last_revise_date} = $self->{last_revise_date};
	$self->{samples} = undef;

    $self;
}

sub rename($) {
	my ($self,$new_name) = @_;
	unless($new_name){
		warn "Need specify a new name and it'' not empty.";
		return 0;
	}
	
	$self->{name} = $new_name;
	return 1;
}

sub has_sample() {
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
	name: "Comment",
	creator: "haibo.sun",
	create_date: "2009-08-05 15:58:20",
	last_revisor: "haibo.sun",
	last_revise_date: "2009-08-05 15:58:20",
	
	samples: {
			"{Host name of Markit::Annotation::HostSampleSet}": {Markit::Annotation::HostSampleSet}
			...
		}
	}
}
