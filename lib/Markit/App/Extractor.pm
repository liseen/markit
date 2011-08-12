package Markit::App::Extractor;

use strict;
use warnings;

#use Smart::Comments;
use JSON::XS;
use File::Spec::Functions;
use Params::Util qw(_HASH _STRING _ARRAY0 _ARRAY _SCALAR);

use Markit;

our %WrapperCache;

sub new {
    my $class = ref $_[0] ? ref shift : shift;

    my $wrapper_dir = shift;
    if (!$wrapper_dir) {
        die "wrapper dir not specified\n"
    }

    my $extractor = new Markit::Wrapper::Extractor;

    my $self = bless {
        wrapper_dir => $wrapper_dir,
        extractor => $extractor
    }, $class;

    $self->init;
    $self;
};

sub set_wrapper_dir {
    my ($self, $dir) = @_;

    $self->{wrapper_dir} = $dir;
}

# cache all wrapper
sub init {
    my ($self) = @_;

    my $json_xs = JSON::XS->new->utf8->relaxed->pretty->allow_blessed->convert_blessed;

    my $wrapper_dir = $self->{wrapper_dir};

    opendir(my $wrapper_dh, $wrapper_dir) or
        die "cannot open wrapper dir $wrapper_dir\n";

    my @apps = grep { /^[^\.]/ && -d catfile($wrapper_dir, $_) } readdir($wrapper_dh);

    for my $app (@apps) {
        $WrapperCache{$app} = {};

        my $app_wrapper_dir = catfile($wrapper_dir, $app);

        opendir(my $app_wrapper_dh, $app_wrapper_dir) or
            die "cannot open app wrapper dir $app_wrapper_dir\n";

        my @domains = grep { /^[^\.]/ && -d catfile($app_wrapper_dir, $_) } readdir($app_wrapper_dh);
        for my $domain (@domains) {
            ### $domain
            my $wrapper_list = [];

            my $domain_wrapper_dir = catfile($app_wrapper_dir, $domain);
            opendir(my $domain_wrapper_dh, $domain_wrapper_dir) or
                die "cannot open domain wrapper dir $domain_wrapper_dir\n";
            my @wrapper_files = grep { /^[^\.]/ && /wrapper$/ && -f catfile($domain_wrapper_dir, $_) } readdir($domain_wrapper_dh);

            for my $w_file (@wrapper_files) {
                open my $in_fh, '<', catfile($domain_wrapper_dir, $w_file) or die "Can't read file: $!";
                my $wrapper_json = do { local $/; <$in_fh> };
                close $in_fh;
                ### $wrapper_json
                my $wrapper_data;
                eval {
                    $wrapper_data = $json_xs->decode($wrapper_json);
                };
                if ($@) {
                    die "cannot decode wrapper file: " . catfile($domain_wrapper_dir, $w_file) . "\n$@\n";
                }
                my $wrapper = Markit::Pattern::build(undef, $wrapper_data);
                push @$wrapper_list, $wrapper;
            }

            close ($domain_wrapper_dir);

            $WrapperCache{$app}->{$domain} = $wrapper_list;
        }

        close($app_wrapper_dh);
    }

    close($wrapper_dh);
}

sub find_wrapper_list {
    my ($self, $app, $domain) = @_;

    if (exists $WrapperCache{$app}) {
        if (exists $WrapperCache{$app}->{$domain}) {
            return $WrapperCache{$app}->{$domain};
        } elsif (exists $WrapperCache{$app}->{default}) {
            return $WrapperCache{$app}->{default};
        } else {
            return undef;
        }
    }

    return undef;
}

sub extract {
    my ($self, $app, $url, $win) = @_;

    if (!$app || !$url || !$win) {
        die "No app or url or win specified\n"
    }

    my $domain = Markit::Util::url2domain($url);
    if (!$domain) {
        die "cannot get domain for url $url";
    }
    my $wrapper_list = $self->find_wrapper_list($app, $domain);
    if (!$wrapper_list) {
        die "No wrapper for domain: $domain found!\n";
    }

    my $extractor = $self->{extractor};

    my $doc = $win->document;
    return $extractor->extract($wrapper_list, $doc);
}

1;
