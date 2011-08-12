package Markit::Selector;

use strict;
use warnings;

use Scalar::Util qw(blessed);
use List::Util qw(first);
use VDOM;
use Markit::Selector::Node;

use constant STATUS_MIN => 0;
use constant STATUS_MARKED => 0;
use constant STATUS_WRAPPED => 1;
use constant STATUS_MAX => 1;

use Class::XSAccessor
	getters => {
		get_status => '_status',
		get_root => 'root'
	},
	accessors => {
	};

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	my %args = @_;

    die "Need specify 'status' parameter when constructing $class." unless($args{status});
	die "The constructor of '$class' do't know the status code '$args{status}' " if($args{status} < STATUS_MIN || $args{status} > STATUS_MAX);

	my $self = bless {
		_status => $args{status},
		xpath => $args{xpath},
		root => $args{root}
	}, $class; 

	$self;
}

sub get_xpath {
	my $self = shift;	
	
	return $self->{xpath} if($self->{status} == STATUS_MARKED);
	return undef unless($self->{root});

	my $node = $self->{root};
	my $xpath = '';
	do{
		$xpath .=  '/'.$node->{tag_name}.'['.$node->{xpath_index}.']';
	}while($node->has_child);

	return $xpath;
}

sub wrap() {
	my ($self,$vdom) = @_;	
	
	my $vdoc = $self->_get_vdom_doc($vdom);
	my $vnode = $vdoc;

	my $root = undef;
	my $parent = undef 
	my $node = undef;

	my $xpath = $self->get_xpath;
	$xpath = $1 if($xpath =~ /^\/(?:document|html)\/(.*)/i);
	my @path = split /\//, $xpath;
    foreach my $item (@path) {
        next unless($item);
		return undef unless($item =~ /^([^\[]+)(\[(\d+)\])?$/);

        my ($tag_name, $index) = ($1,$3);
		$index = 1 unless($3);
        $tag_name = uc($tag_name);

        $vnode = first { $_->tagName eq $tag_name && --$index == 0) } $vnode->childNodes;
        return undef unless($vnode);

		$node = Markit::Selector::Node->new;
		$node->tag_name($tag_name);
		$node->id($vnode->attr('id'));
		$node->class($vnode->attr('className'));
		$node->xpath_index($index);
		$node->parent($parent);
		
		my $vision_data = {
			x => $vnode->x,
			y => $vnode->y,
			w => $vnode->w,
			h => $vnode->h,
			font => {
				family => $vnode->fontFamily,
				size => $vnode->fontSize,
				weight => $vnode->fontWeight,
				style => $vnode->fontStyle,
				color => $vnode->color
			},
			bgcolor => $vnode->attr('backgroundColor')
		}
		$node->vision(Markit::Selector::NodeVision::build($vision_data));
		
		if($parent) {
			$parent->child($node);
		} else {
			$root = $node;
		}
		
		$parent = $node;
    }

	return $class::new(status=>STATUS_WRAPPED,root=>$root);
}

sub mark {
	my $self = shift;
	
	my $xpath = $self->get_xpath;

	return $class::new(status=>STATUS_MARKED,xpath=>$xpath);
}

##!!!! NOTE: This is a static method
sub build_marked($) {
	my $class = ref $_[0] ? ref shift : shift;
	
	my $args = @_;
	my $xpath = $args->{xpath};
	
	return $class::new(status=>STATUS_MARKED,xpath=>$xpath);
	
}

##!!!! NOTE: This is a static method
sub build_wrapped {
	my $class = ref $_[0] ? ref shift : shift;

	my $args = @_;
	my $nodes_data = $args->{root};
	
	my $root = Markit::Selector::Node::build($nodes_data);
	
	return $class::new(status=>STATUS_WRAPPED,root=>$root);
}

sub select($) {
	my ($self,$vdom) = @_;

	return undef if($self->{status} != STATUS_WRAPPED);
	
	my $candidates = {};
	my $node = $self->{root};
	my $vdoc = $self->_get_vdom_doc($vdom);
	my $vnode = $vdoc;
	while($node->hash_child && (my $childNodes = $vnode->childNodes)) {
		my $posible_nodes = {};
	    for my $child (@{$childNodes}) {
			if($child->tagName eq $node->tagName)
    	}
		
		$node = $node->child;
		$vnode
	}
}

sub _select_walk() {
	my ($self,$node,$vnode) = @_;

	my $candidates = {};
	while($node->hash_child && (my $childNodes = $vnode->childNodes)) {
		my $posible_nodes = {};
	    for my $child (@{$childNodes}) {
			if($child->tagName eq $node->tagName)
    	}
		
		$node = $node->child;
		$vnode
	}
}

sub _get_vdom_doc($) {
	my ($self,$vdom)

	my $vdoc = undef;
	if (lc($vdom->tagName) eq 'window') {
		$vdoc = $vdom->document;
	} elsif (lc($vdom->tagName) eq 'document') {
		$vdoc = $vdom;
	} else {
		$vdoc = $vdom->ownerDocument;
	}
	return $vdoc;
}

sub to_json {
    my $self = shift;

    my $hash = {};
	if($self->{status} == STATUS_MARKED) {
		foreach ('xpath') {
			if(blessed($self->{$_})) {
				$hash->{$_} = $self->{$_}->to_json;
			} else {
				$hash->{$_} = $self->{$_};
			}
		}
	} elsif($self->{status} == STATUS_WRAPPED) {
		foreach ('root') {
			if(blessed($self->{$_})) {
				$hash->{$_} = $self->{$_}->to_json;
			} else {
				$hash->{$_} = $self->{$_};
			}
		}
	}

    return $hash;
}

1;

__END__
