package Markit::LogicItem::AndItem;

use strict;
use warnings;

use base 'Markit::LogicItem::CompositeItem';

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;
	$args{_name} = "AND";
	$args{_code} = $class->SUPER::CODE_AND;
	my $self = $class->SUPER::new(%args);

	$self;
}

1;

__END__
