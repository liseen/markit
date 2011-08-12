package Markit::DataType::Integer;

use strict;
use warnings;

use base 'Markit::DataType::_RegexBase';

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;
	$args{_default_value} = 0; 
	$args{_common_regex} = qr/^(\d+)$/xsm; 
	$args{_wise_regex} = qr/(\d+)/x; 
	my $self = $class->SUPER::new(%args);

	$self;
}

1;

__END__
