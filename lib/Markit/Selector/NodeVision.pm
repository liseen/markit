package Markit::Selector::NodeVision;

use strict;
use warnings;

use Markit::Selector::NodeFont;

use Class::XSAccessor
	getters => {
	},
	accessors => {
		x => 'x',
		y => 'y',
		w => 'w',
		h => 'h',
		font => 'font',
		bgcolor => 'bgcolor'
    },
	predicates => {
		has_font => 'font',
	};

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	my $self = bless {
		x => undef,
		y => undef,
		w => undef,
		h => undef,
		font => undef,
		bgcolor => undef
	}, $class; 

	$self;
}

##!!!! NOTE: This is a static method
sub build {
	my $class = ref $_[0] ? ref shift : shift;
	
	my $vision_data = @_;
	
	return undef unless($vision_data);
	
	my $vision = $class->new;
	$vision->x($vision_data->{x}) if(exists $vision_data->{x});
	$vision->y($vision_data->{y}) if(exists $vision_data->{y});
	$vision->w($vision_data->{w}) if(exists $vision_data->{w});
	$vision->h($vision_data->{h}) if(exists $vision_data->{h});
	$vision->bgcolor($vision_data->{bgcolor}) if(exists $vision_data->{bgcolor});
	$vision->font(Markit::Selector::NodeFont::build($vision_data->{font})) if($vision_data->{font});
	
	return $vision;
}

1;

__END__
