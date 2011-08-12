package Markit::LogicItem::NotItem;

use strict;
use warnings;

use base 'Markit::LogicItem::CompositeItem';

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;
	$args{_name} = "NOT";
	$args{_code} = $class->SUPER::CODE_NOT;
	my $self = $class->SUPER::new(%args);

	$self;
}

1;

__END__
