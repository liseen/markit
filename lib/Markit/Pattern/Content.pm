package Markit::Pattern::Content;

use strict;
use warnings;

use Markit::DataType::Constant;

#members
use Class::XSAccessor
	getters => {
		get_attr_name => 'attr_name',
		get_val_type => 'val_type'
	},
	accessors => {
    };


sub new {
	my $class = ref $_[0] ? ref shift : shift;

	my %args = @_;

    die "Need specify 'attr_name' parameter when constructing $class." unless($args{attr_name});
	
	my $val_type = $args{val_type};
	$val_type = Markit::DataType::Constant::TYPE_TEXT unless($args{val_type});
	die "Unkown val_type '$val_type' for constructing $class." unless(Markit::DataType::Constant::CLASS->{$val_type});

	my $self = bless {
		attr_name => $args{attr_name},
		val_type => $val_type,
		}, $class; 

	$self;
}

1;

__END__
