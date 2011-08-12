package Markit::Wrapper;

use strict;
use warnings;

use base 'Markit::Pattern';

#use Smart::Comments;

1;
__END__

{
    "@url": "http://www.yahoo.cn",
    "comment": {
        "@type": "node",
        "@occur_type": "multiple",
        "@filters": {
                filters: [
                    { conditions: [] }
                ]
                },

        "title": {},
        "pub_date": {},
        "body": {"@type":"text",  "@occur_type": "single"},
    }
};
