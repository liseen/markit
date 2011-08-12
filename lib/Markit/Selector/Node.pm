package Markit::Selector::Node;

use strict;
use warnings;

use Scalar::Util qw(blessed);
use Markit::Selector::NodeVision;

use Class::XSAccessor
	getters => {
	},
	accessors => {
		tag_name => 'tag_name',
		id => 'id',
		class => 'class',
		xpath_index => 'xpath_index',
		vision => 'vision',
		child => 'child',
		parent=> '_parent'
    },
	predicates => {
		has_vision => 'vision',
		has_child => 'child',
		has_parent => '_parent',
	};


sub new {
	my $class = ref $_[0] ? ref shift : shift;

	my $self = bless {
		tag_name => undef,
		id => undef,
		class => undef,
		xpath_index => undef,
		vision => undef,
		child => undef,
		_parent => undef
		}, $class; 

	$self;
}

##!!!! NOTE: This is a static method
sub build {
	my $class = ref $_[0] ? ref shift : shift;
	
	my $nodes_data = @_;
	
	return undef unless($nodes_data);
	
	my $root = undef;
	my $node = undef;
	my $parent = undef;
	do{
		return undef if(!$nodes_data->{tag_name} || $nodes_data->{xpath_index});

		$node = $class->new;
		$node->tag_name($nodes_data->{tag_name});
		$node->id($nodes_data->{id}) if(exists $nodes_data->{id});
		$node->class($nodes_data->{class}) if(exists $nodes_data->{class});
		$node->xpath_index($nodes_data->{xpath_index});
		$node->vision(Markit::Selector::NodeVision::build($nodes_data->{vision})) if(exists $nodes_data->{vision});
		$node->parent($parent);
		
		if($parent) {
			$parent->child($node);
		} else {
			$root = $node;
		}

		$parent = $node;
	}while($nodes_data->{child} && ($nodes_data = $nodes_data->{child}));
	
	return $root;
}

sub to_json {
    my ($self) = @_;

    my $hash = {};
    while (my ($key, $val) = each %$self) {
        next if $key =~ /^_/;

		if(blessed($self->{$key})) {
			$hash->{$key} = $self->{$key}->to_json;
		} else {
			$hash->{$key} = $val;
		}
    };

    $hash;
}

1;

__END__

{
	tag_name: "",
	id: "",
	class: "",
	xpath_index: 0,
	vision: {Markit::Selector::NodeVision},
	child: {Markit::Selector::Node},
	parent: {Markit::Selector::Node}
}
