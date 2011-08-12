package Markit::DataType::Decimal;

use strict;
use warnings;

use base 'Markit::DataType::_RegexBase';

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;
	$args{_default_value} = 0.0;
	$args{_common_regex} = qr/^(\d+\.\d+)$/xsm;
	$args{_wise_regex} = qr/(\d+\.\d+)/x;
	my $self = $class->SUPER::new(%args);

	$self;
}

1;

__END__
