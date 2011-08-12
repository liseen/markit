package Markit::LogicItem::ObjectItem;

use strict;
use warnings;

use base 'Markit::LogicItem::CompositeItem';

sub new {
	my ($class,$object) = ref $_[0] ? ref shift : shift;
	
	my %args = @_;
	$args{_name} = "OBJECT";
	$args{_code} = $class->SUPER::CODE_OBJECT;
	$args{_object} = $object;
	my $self = $class->SUPER::new(%args);

	$self;
}

1;

__END__
