package Markit::Selector::NodeFont;

use strict;
use warnings;

use Class::XSAccessor
	getters => {
	},
	accessors => {
		family => 'family',
		size => 'size',
		weight => 'weight',
		style => 'style',
		color => 'color'
	};

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	my $self = bless {
		family => undef,
		size => undef,
		weight => undef,
		style => undef,
		color => undef
	}, $class; 

	$self;
}

##!!!! NOTE: This is a static method
sub build {
	my $class = ref $_[0] ? ref shift : shift;
	
	my $font_data = @_;
	
	return undef unless($font_data);
	
	my $font = $class->new;
	$font->family($font_data->{family}) if(exists $font_data->{family});
	$font->size($font_data->{size}) if(exists $font_data->{size});
	$font->weight($font_data->{weight}) if(exists $font_data->{weight});
	$font->style($font_data->{style}) if(exists $font_data->{style});
	$font->color($font_data->{color}) if(exists $font_data->{color});

	return $font;
}

1;

__END__
