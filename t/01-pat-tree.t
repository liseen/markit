#!/usr/bin/evn perl

use strict;
use warnings;

#use Smart::Comments;
use FindBin;
use JSON::XS;
use Test::More 'no_plan';

use lib "$FindBin::Bin/../lib";
use Markit;

my $pattern_json = '{
        "url": "http://www.yahoo.cn",
        "childPatterns": {
            "comment": {
                "type": "node",
                "occur_type": "multiple",
                "xpath": "/html/body/",

                "childPatterns": {
                    "title": {},
                    "pub_date": {}
                }
            }
        }
    }';


my $pattern_hash = decode_json $pattern_json;

my $pattern = Markit::Pattern->new->build($pattern_hash);

ok $pattern, "New pattern ok";
my $sub_patterns = $pattern->childPatterns;
ok $sub_patterns, "Have child Patterns ok";
my $sub_num = scalar (keys %$sub_patterns);
is $sub_num, 1, "Have a child Pattern ok";

ok $sub_patterns->{comment}, "comment pattern parse ok";
my $title_type = $sub_patterns->{comment}->childPatterns->{title}->type;
is $title_type, $Markit::Pattern::TEXT, "title type ok";
