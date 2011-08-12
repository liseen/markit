package Markit::DataType::Cidr;

use strict;
use warnings;

use base 'Markit::DataType::_RegexBase';

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;
	$args{_default_value} = '0.0.0.0';
	$args{_common_regex} = qr/^((\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}))$/xsm; 
	$args{_wise_regex} = qr/((\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}))/x;
	$args{_validate_proc} = \&validate;
	my $self = $class->SUPER::new(%args);

	$self;
}

#NOTE: This is a callback method
sub validate {
	my %args = @_;
	for(my $i = 1;$i < $args{count};$i++){
		return undef if($args{$i} > 255);
	}
	return $args{0};
}

1;

__END__

=head1 DESCRIPTION
	It currently support IPv4 only.
=cut

