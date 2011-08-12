package Markit::DataType::Email;

use strict;
use warnings;

use Email::Valid;
use Email::Find;

use base 'Markit::DataType::_Base';

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;

	my $self = $class->SUPER::new(%args);
	$self->{_default_value} = '';

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
		unless($wise) {
			my $addr = Email::Valid->address($text);
			if($addr){
				$self->{_valid} = 1;
				if($self->{_multiple}) {
					$self->{_value} = [$addr];
				} else {
					$self->{_value} = $addr;
				}
				return;
			}
		} else {
			my @emails = ();
			my $finder = Email::Find->new(sub {
				my $addr = Email::Valid->address(shift);
				push @emails, $addr if($addr);
			});
			$finder->find(\$text);
			if(scalar(@emails) > 0) {
				$self->{_valid} = 1;
			}
			if($self->{_multiple}) {
				$self->{_value} = [map {$_} @emails];	
			} else {
				$self->{_value} = $emails[0];
				return;
			}
		}
	}
}

1;

__END__

=head1 DESCRIPTION
	
=cut
