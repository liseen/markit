package Markit::DataType::_RegexBase;

use strict;
use warnings;

use base 'Markit::DataType::_Base';

#members
use Class::XSAccessor
	getters => {
		_common_regex => '_common_regex',
		_wise_regex => '_wise_regex'
	};

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;
	my $self = $class->SUPER::new(%args);
	
	$self->{_common_regex} = $args{_common_regex};
	$self->{_wise_regex} = $args{_wise_regex};
	$self->{_validate_proc} = $args{_validate_proc};
	
	$self->set_text($args{text},$args{wise},$args{exactly});

	$self;
}

sub set_text($$$) {
	my ($self,$text,$wise,$exactly) = @_;
	$wise = 1 unless(defined $wise);
	$exactly = 1 unless(defined $exactly);
	
	#
	$self->{_valid} = 0;
	$self->{_value} = undef;

	#
	if(!$exactly && (!defined($text) || $text eq '')){
		$self->{_valid} = 1;
		if($self->{_multiple}) {
			$self->{_value} = [$self->{_default_value}];
		} else {
			$self->{_value} = $self->{_default_value};
		}
		return;
	}

	if(defined $text) {
		my $regex = $self->{_common_regex};
		$regex = $self->{_wise_regex} if($wise); 

		while($text =~ /$regex/og){
			my $value = $1;
			if(defined $self->{_validate_proc}){
				my %param = (self=>$self,wise=>$wise,exactly=>$exactly,count=>(scalar(@+) - 1));
				for(my $i = 1;$i < scalar(@+);$i++) {
					if(defined $-[$i] && defined $+[$i]) {
						$param{($i - 1)} = substr($text,$-[$i],$+[$i] - $-[$i]);
					} else {
						$param{($i - 1)} = undef;
					}
				}
				$value = &{$self->{_validate_proc}}(%param);
			}

			if(defined $value) {
				$self->{_valid} = 1;
				if($self->{_multiple}) {
					push @{$self->{_value}},$value;	
				} else {
					$self->{_value} = $value;
					return;
				}
			}
		}
	}
}

1;

__END__
