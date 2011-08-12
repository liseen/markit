package ProcCtl;
use POSIX ":sys_wait_h";
use strict;


my @forked;
my @died;
my $end;
my $cnt;

sub SIG_CHLD {
    my $child;
    while (($child = waitpid(-1,WNOHANG)) > 0) {
        push @died, $child;
        if ( scalar @died == $cnt ) {
            $end = 1;
        }
    }
    $SIG{CHLD} = \&SIG_CHLD;  # loathe sysV
}

sub Init {
	$cnt = shift;
	$SIG{CHLD} = \&SIG_CHLD;
	$end = 0;
	@forked = ();
	@died = ();
}

sub Fork {
	my ($child_work, $child_arg) = @_;
	if (fork){
		push @forked, 1;
	} else {
		$child_work->($child_arg);
		exit 0;
	}

}

sub Wait {
	sleep 1 while ( ! $end );
}

1;
