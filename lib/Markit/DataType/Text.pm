package Markit::DataType::Text;

use strict;
use warnings;

use base 'Markit::DataType::_Base';

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my ($text,$wise) = @_;

	my $self = $class->SUPER::new(%args);
	
	$self->set_text($text,$wise);

	$self;
}

sub set_text($$$) {
	my ($self,$text,$wise) = @_;
	$wise = 1 unless(defined $wise);
	
	$text = '' if($wise && !defined($text));
	$self->{_valid} = 1;
	if($self->{_multiple}) {
		push @{$self->{_value}},$text;	
	} else {
		$self->{_value} = $text;
	}
}

1;

__END__
