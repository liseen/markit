package Markit::LogicItem::OrItem;

use strict;
use warnings;

use base 'Markit::LogicItem::CompositeItem';

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;
	$args{_name} = "OR";
	$args{_code} = $class->SUPER::CODE_OR;
	my $self = $class->SUPER::new(%args);

	$self;
}

1;

__END__
