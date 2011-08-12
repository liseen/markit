package Markit::DataType::DateTime;

use strict;
use warnings;

use Date::Manip;
use base 'Markit::DataType::_RegexBase';

use constant DATE_DAY_MONTH => [31,28,31,30,31,30,31,31,30,31,30,31];

our $ZH_HYPHEN_UTF8 = "\xef\xbc\x8d"; # －
our $ZH_YEAR_UTF8 = "\xe5\xb9\xb4"; # 年
our $ZH_MONTH_UTF8 = "\xe6\x9c\x88"; # 月
our $ZH_DAY_UTF8 = "\xe6\x97\xa5"; # 日
our $ZH_DATE_UTF8 = "\xe5\x8f\xb7"; # 号
our $ZH_AM_PART1_UTF8 = "\xe4\xb8\x8a"; # 上
our $ZH_PM_PART1_UTF8 = "\xe4\xb8\x8b"; # 下
our $ZH_AM_PM_PART2_UTF8 = "\xe5\x8d\x88"; # 午
our $ZH_COLON_UTF8 = "\xef\xbc\x9a"; # ：
our $ZH_HOUR_UTF8 = "\xe6\x97\xb6"; # 时
our $ZH_MINUTE_UTF8 = "\xe5\x88\x86"; # 分
our $ZH_SECOND_UTF8 = "\xe7\xa7\x92"; # 秒

our $IGNORE_CHAR_RE = "(?:[\\s\\t]*)";
our $DATE_PART1_RE = "(\\d{1,4}) $IGNORE_CHAR_RE ((?:/|\\.|-|$ZH_HYPHEN_UTF8|$ZH_YEAR_UTF8))";
our $DATE_PART2_RE = "(\\d{1,2}) $IGNORE_CHAR_RE ((?:/|\\.|-|$ZH_HYPHEN_UTF8|$ZH_MONTH_UTF8))";
our $DATE_PART3_RE = "(\\d{1,4})((?:\\s|\\t|$IGNORE_CHAR_RE $ZH_DAY_UTF8|$IGNORE_CHAR_RE $ZH_DATE_UTF8))?";
our $TIME_PREFIX_RE = "((?:AM|PM|$ZH_AM_PART1_UTF8 $IGNORE_CHAR_RE $ZH_AM_PM_PART2_UTF8|$ZH_PM_PART1_UTF8 $IGNORE_CHAR_RE $ZH_AM_PM_PART2_UTF8))";
our $TIME_HOUR_RE = "(\\d{1,2})";
our $TIME_HOUR_SEP_RE = "((?:\\:|$ZH_HOUR_UTF8))";
our $TIME_MINUTE_RE = "(\\d{1,2})";
our $TIME_MINUTE_SEP_RE = "((?:\\:|$ZH_MINUTE_UTF8))";
our $TIME_SECOND_RE = "(\\d{1,2})";
our $TIME_SECOND_SEP_RE = "((?:\\s|\\t|$ZH_SECOND_UTF8))";

#members
use Class::XSAccessor
	getters => {
		canonical_value => 'canonical_value',
	};

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	my %args = @_;

	my $time_re = join($IGNORE_CHAR_RE, "$TIME_HOUR_RE?","$TIME_HOUR_SEP_RE?","$TIME_MINUTE_RE?","$TIME_MINUTE_SEP_RE?","$TIME_SECOND_RE?","$TIME_SECOND_SEP_RE?" );
	my $date_time_re = join($IGNORE_CHAR_RE,"$DATE_PART1_RE?", $DATE_PART2_RE, $DATE_PART3_RE, "$TIME_PREFIX_RE?",$time_re);

	$args{_common_regex} = qr{^($date_time_re)$}xism;
	$args{_wise_regex} = qr{($date_time_re)}xi;
	$args{_validate_proc} = \&validate;
	my $self = $class->SUPER::new(%args);
	
	$self->_manip_parse(@_) unless($self->is_valid);

	$self;
}

sub set_text($$$) {
	my $self = shift;
	$self->SUPER::set_text(@_);

	$self->_manip_parse(@_) unless($self->is_valid);
}

sub _manip_parse($$$) {
	my ($self,$text,$wise,$exactly) = @_;
	return unless($text);
	
	unless($wise) {
		my $date = ParseDate($text);
		if($date) {
			$self->{_valid} = 1;
			$self->{_value} = UnixDate($date,"%Y-%m-%d %H:%M:%S");
			$self->{canonical_value} = $self->{_value};
		}
	}
}

#NOTE: This is a callback method
sub validate {
	my %args = @_;
	my ($date_part1,$date_part1_sep) = ($args{1},$args{2});
	my ($date_part2,$date_part2_sep) = ($args{3},$args{4});
	my ($date_part3,$date_part3_sep) = ($args{5},$args{6});
	my ($time_prefix) = ($args{7});
	my ($time_hour) = ($args{8});
	my ($time_hour_sep) = ($args{9});
	my ($time_minute) = ($args{10});
	my ($time_minute_sep) = ($args{11});
	my ($time_second) = ($args{12});
	my ($time_second_sep) = ($args{13});

	my @now = localtime;
	my $cur_year = 1900 + $now[5];
	
	my ($year,$month,$day) = (undef,$date_part2,undef);
	if($date_part1_sep) {
		if($date_part1_sep eq $ZH_YEAR_UTF8 || $date_part1 > 99) {
			$year = $date_part1;
			$day = $date_part3;
		} elsif($date_part3 > 99 || $date_part3 > 12) {
			$year = $date_part3;
			$day = $date_part1;
		} else {
			$year = $date_part1;
			$day = $date_part3;
		}
		
		my $year_length = length($year);
		return undef if($year_length != 2 && $year_length != 4);
		
		$year = substr($cur_year,0,2).$year if($year_length == 2);		
	} else {
		$year = $cur_year;
		$day = $date_part3;	
	}

	my ($hour_add,$hour,$minute,$second) = (0,0,0,0);
	if($time_prefix) {
		$time_prefix =~ s/$IGNORE_CHAR_RE//g;
		$hour_add = 12 if(uc($time_prefix) eq 'PM' || $time_prefix eq "$ZH_PM_PART1_UTF8$ZH_AM_PM_PART2_UTF8");
	}
	
	if($time_hour && $time_hour_sep && $time_minute) {
		$hour = $time_hour;
		$minute = $time_minute;
		$second = $time_second if($time_minute_sep && $time_second);
	}
	
	return undef if($month > 12 || $month == 0 || $day > DATE_DAY_MONTH->[$month] || $day == 0 || $hour > 23 || $minute > 59 || $second > 59);

	my $canonical_value = sprintf("%d-%0.2d-%0.2d %0.2d:%0.2d:%0.2d",$year,$month,$day,$hour,$minute,$second);

	return $canonical_value;
}

1;

__END__

=head1 DESCRIPTION
	

=head1
日期：
1、2009/03/10
2、03/10/2009
3、03/10
4、2009.03.10
5、03.10
6、2009-03-10
7、03-10
8、2009年03月10日
9、03月10日

日期与时间分隔：
1、空格
2、当日期以日或者号结尾时可为空

时间前缀：
1、上午
2、下午
3、AM，大小写都可
4、PM，大小写都可

时间：
1、不出现时间
2、15:07
3、15:07:58
5、15时07
6、15时07分
7、15时07分58
8、15时07分58秒

=cut
