package Smart::Comments::JSON;

use strict;
use warnings;

use JSON::XS;
use Filter::Util::Call;
use encoding 'utf8';
#use Data::Structure::Util qw( utf8_on );

my $json_xs = JSON::XS->new
                      ->allow_nonref
                      ->pretty
                      ->convert_blessed
                      ->canonical;

sub import {
    my ($class, $prefix) = @_ ;
    if (!defined $prefix) {
        $prefix = '###';
    }
    filter_add(bless \$prefix, __PACKAGE__) ;
}

sub filter {
    my ($self) = @_ ;
    my ($status) ;
    my $prefix = $$self;
    #warn "Prefix: $prefix\n";

    s/^\s*\Q$prefix\E\s+(.*)/$self->gen_code($1)/eg
        if ($status = filter_read()) > 0;
    $status;
}

sub gen_code {
    my ($self, $spec) = @_;
    my $class = ref $self;
    my $prefix = quotemeta $$self;
    if ($spec =~ /(.*?:)\s*(.*)/) {
        my ($desc, $expr) = ($1, $2);
        my @vals = split /\s+/, $expr;
        $expr = join ', ', @vals;
        my $code = "warn \"$prefix $desc ".quotemeta($expr).
            "\\n\". $class->dump_all(\"$prefix\", $expr).\"\\n\";";
        #warn "CODE: $code\n";
        return $code;
    } elsif ($spec =~ /^\s*([\$\@\%\&].+)/) {
        my $val_list = $1;
        my @vals = map { s/^[\@\%]/\\$&/;$_ } split /\s+/, $val_list;
        my $expr = join ', ', @vals;
        my $code = "warn \"$prefix ".quotemeta($val_list).
            "\\n\". $class->dump_all(\"$prefix\", $expr).\"\\n\";";
        #warn "CODE: $code\n";
        return $code;
    } elsif ($spec =~ /\.\.\.\s*$/) {
        return "warn \"$prefix ".quotemeta($spec)."\\n\";";
    } else {
        die "Syntax error in the smart comment of prefix $$self: $spec\n";
    }
}

sub dump_all {
    my $class = shift;
    my $prefix = shift;
    my $s = join "\n", map { $json_xs->encode($_) } @_;
    $s =~ s/^/$prefix     /gms;
    $s;
}

1;

