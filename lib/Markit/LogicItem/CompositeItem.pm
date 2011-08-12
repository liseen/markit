package Markit::LogicItem::CompositeItem;

use strict;
use warnings;

use Switch;

use base 'Markit::LogicItem::_Item';

use constant CODE_MIN => 0;
use constant CODE_OBJECT => 0;
use constant CODE_AND => 1;
use constant CODE_OR => 2;
use constant CODE_NOT => 3;
use constant CODE_MAX => 3;

use Class::XSAccessor
	getters => {
		get_name => '_name',
		get_code => '_code',
		get_object => '_object'
	};


sub new {
	my $class = ref $_[0] ? ref shift : shift;

	my %args = @_;
	die "Need specify '_code' parameter when constructing $class." unless($args{_code});
	die "The constructor of '$class' do't know the code '$args{_code}' " if($args{_code} < CODE_MIN || $args{_code} > CODE_MAX);
	die "Need specify '_object' parameter when constructing $class." if(!$args{_object} && $args{_code} == CODE_OBJECT);

	my $self = bless {
		_name => $args{_name},
		_code => $args{_code},
		_object => $args{_object},
		_sub_items => [],
		}, $class; 

	$self;
}

sub has_items {
	my $self = shift;

	return ($self->{_sub_items} && scalar($self->{_sub_items}) > 0);
}

sub add_item($) {
	my ($self,$object) = @_;
	
	return 0 if($self->{_code} == CODE_OBJECT || 
		($self->{_code} == CODE_NOT && scalar(@{$self->{_sub_items}}) > 0));

	push @{$self->{_sub_items}},$object;
	return 1;
}

sub remove_item($) {
	my ($self,$index) = @_;
	
	return 0 if($index < 0 || $index > scalar(@{$self->{_sub_items}}));

	splice @{$self->{_sub_items}},$index,1;
	return 1;
}

sub test {
	my $self = shift;
	if($self->{_code} == CODE_OBJECT){
		return $self->{_object}->test ? 1:0;
	}
	
	return 0 if(scalar(@{$self->{_sub_items}}) == 0);
	
	switch ($self->{_code}) {
		case CODE_AND {
			foreach (@{$self->{_sub_items}}) {
				return 0 unless($_->test);
			}
			return 1;
		};
		case CODE_OR {
			foreach (@{$self->{_sub_items}}) {
				return 1 if($_->test);
			}
		};
		case CODE_NOT {
			foreach (@{$self->{_sub_items}}) {
				return $_->test ? 0:1;
			}
		};
	}

	return 0;
}

1;

__END__
