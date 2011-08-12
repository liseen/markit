package Markit::DataType::Constant;

use strict;
use warnings;

use constant {
	TYPE_TEXT => 'text',
	TYPE_INT => 'integer',
	TYPE_DECIMAL => 'decimal',
	TYPE_NUMBER => 'number',
	TYPE_DATETIME => 'datetime',
	TYPE_CIDR => 'cidr',
	TYPE_URL => 'url',
	TYPE_EMAIL => 'email'
};

no strict 'subs';
use constant CLASS => {
	(TYPE_TEXT) => 'Markit::DataType::Text',
	(TYPE_INT) => 'Markit::DataType::Integer',
	(TYPE_DECIMAL) => 'Markit::DataType::Decimal',
	(TYPE_NUMBER) => 'Markit::DataType::Number',
	(TYPE_DATETIME) => 'Markit::DataType::DateTime',
	(TYPE_CIDR) => 'Markit::DataType::Cidr',
	(TYPE_URL) => 'Markit::DataType::Url',
	(TYPE_Email) => 'Markit::DataType::Email'
};

use strict 'subs';

1;

__END__
