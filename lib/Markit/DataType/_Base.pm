package Markit::DataType::_Base;

use strict;
use warnings;

#members
use Class::XSAccessor
	getters => {
		is_valid => '_valid',
		value => '_value',
		default_value => '_default_value',
		multiple => '_multiple'
	};

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;

	my $self = bless {
		_valid => 0,
		_value => undef,
		_default_value => $args{_default_value},
		_multiple => $args{_multiple}
		}, $class; 
	
	$self;
}

1;

__END__
