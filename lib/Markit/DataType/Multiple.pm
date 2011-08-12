package Markit::DataType::Multiple;

use strict;
use warnings;

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;
	die "Need specify 'class' parameter when constructing $class." unless($args{class});

	$args{_multiple} = 1;
	
	my $target_class = "Markit::DataType::$args{class}";
	#require $target_class;
	my $self = $target_class->new(%args);

	$self;
}

1;

__END__
