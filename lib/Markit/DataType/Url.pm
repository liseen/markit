package Markit::DataType::Url;

use strict;
use warnings;

use URI::URL;
use URI::Find;

use base 'Markit::DataType::_Base';

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;

	my $self = $class->SUPER::new(%args);

	$self->set_text($args{text},$args{base_url},$args{wise},$args{exactly});

	$self;
}

sub set_text($$$$) {
	my ($self,$text,$base_url,$wise,$exactly) = @_;
	$wise = 1 unless(defined $wise);
	$exactly = 1 unless(defined $exactly);

	#
	$self->{_valid} = 0;
	$self->{_value} = undef;

	#
	if(!$exactly && (!defined($text) || $text eq '')){
		if($base_url) {
			$self->{_valid} = 1;
			if($self->{_multiple}) {
				$self->{_value} = [$base_url];
			} else {
				$self->{_value} = $base_url;
			}
			return;
		}
	}

	if(defined $text) {
		unless($wise) {
			my $url = URI->new($text)->abs($base_url)->canonical;
			
			if($url->scheme){
				$self->{_valid} = 1;
				if($self->{_multiple}) {
					$self->{_value} = [$url->as_string];
				} else {
					$self->{_value} = $url->as_string;
				}
				return;
			}
		} else {
			my @uris = ();
			my $finder = URI::Find->new(sub {
				my($uri) = shift;
				push @uris, $uri;
			});
			$finder->find(\$text);
			if(scalar(@uris) > 0) {
				$self->{_valid} = 1;
			}
			if($self->{_multiple}) {
				$self->{_value} = [map {$_->canonical->as_string} @uris];	
			} else {
				$self->{_value} = $uris[0];
				return;
			}
		}
	}
}

1;

__END__

=head1 DESCRIPTION
	
=cut
