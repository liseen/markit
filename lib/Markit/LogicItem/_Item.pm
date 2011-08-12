package Markit::LogicItem::_Item;

use strict;
use warnings;

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	my $self =  bless {} $class;
	
	$self;
}

sub test {
	my $self = shift;

	return 1;
}

1;

__END__
