#!/usr/bin/env perl

# fax2slack.pl (Ver.20170328) by Masahiko OHKUBO <https://github.com/mah-jp/fax2slack>
# usage: fax2slack.pl [-n] [-i INIFILE]

use strict;
use warnings;
use lib '/home/mah/perl5/lib/perl5';
use HTML::Template;
use Tie::Storable;
use Encode;
use Config::Tiny;
use Getopt::Std;
use Unicode::Japanese;
use List::Compare;
use URI::Fetch;
use JSON;
#use Data::Dumper;

my %opt;
Getopt::Std::getopts('i:n', \%opt);
my $file_ini = $opt{'i'} || 'fax2slack_test.ini';
my $config = Config::Tiny->new;
$config = Config::Tiny->read($file_ini);
my $flag_dryrun = $opt{'n'} || 0;

tie my @fax_old => 'Tie::Storable', $config->{'history'}->{'file'};
my($ref_fax_now, $ref_fax_diff) = &DIFF_FAX($config->{'xerox'}->{'url'}, \@fax_old);
if (($flag_dryrun) || (scalar(@fax_old) > 0)) {
	if (($flag_dryrun) || ((ref($ref_fax_diff) eq 'ARRAY') && scalar(@{$ref_fax_diff}) > 0)) {
		my(@fax_diff) = @{$ref_fax_diff};
		if ($flag_dryrun) {
			@fax_diff = @fax_old;
		}
		while(@fax_diff) {
			my @tmp = split('\t', shift(@fax_diff));
			my %data;
			$data{'page'} = $tmp[4];
			$data{'datetime'} = $tmp[7];
			($data{'date'}, $data{'time'}) = split(' ', $tmp[7], 2);
			if ($flag_dryrun) {
				&POST_SLACK(&MAKE_TEXT(\%data), $config->{'slack'}, $flag_dryrun);
			} else {
				if (defined($config->{'slack'}->{'url'}) && ($config->{'slack'}->{'url'} ne '')) {
					&POST_SLACK(&MAKE_TEXT(\%data), $config->{'slack'});
				}
			}
		}
	}
}
@fax_old = @$ref_fax_now;
exit;

# ========================================

sub MAKE_TEXT {
	my($ref_data) = @_;
	my $template = HTML::Template->new(filename => $config->{'slack'}->{'template'}, die_on_bad_params => 0, global_vars => 1);
	$template->param(
		FAX_PAGE => $$ref_data{'page'},
		FAX_DATETIME => $$ref_data{'datetime'},
		FAX_DATE => $$ref_data{'date'},
		FAX_TIME => $$ref_data{'time'},
		FAX_FLAG_PAGES => $$ref_data{'page'} - 1,
	);
	return($template->output);
}

sub POST_SLACK {
	my($text, $ref_slack, $flag_dryrun) = @_;
	my $data = sprintf(
			'payload={"channel": "%s", "username": "%s", "text": "%s"}',
			$$ref_slack{'channel'}, $$ref_slack{'username'}, Encode::decode('utf-8', $text)
		);
	my $command = sprintf("curl -X POST --data-urlencode '%s' %s", $data, $$ref_slack{'url'});
	if (defined($flag_dryrun) && ($flag_dryrun)) {
		printf('%s' . "\n", $command);
	} else {
		`$command`;
	}
	return;
}

# for http://192.168.XXX.XXX/jbhist.htm
sub DIFF_FAX {
	my($url_source, $ref_old) = @_;
	my($res, $ref_now);
	$res = URI::Fetch->fetch($url_source) or die URI::Fetch->errstr;
	if ($res->is_success) {
		my @text = split(/\n/, Unicode::Japanese->new($res->content, 'sjis')->get);
		while(@text) {
			my $line = shift(@text);
			if ($line =~ /^var jHst=/) {
				$line =~ s/;\s*$//;
				my $json_text = (split('=', $line, 2))[1];
				$json_text =~ s/'/"/g;
				$ref_now = &PICKUP_FAX(JSON->new()->decode($json_text));
				last;
			}
		}
	}
	my $lc = List::Compare->new('--unsorted', $ref_old, $ref_now);
	my @diff = $lc->get_Ronly;
	return($ref_now, \@diff);
}

sub PICKUP_FAX {
	my($ref_data) = @_;
	my(@data) = @$ref_data;
	my(@data_fax);
	for (my $i = 0; $i < scalar(@data); $i ++) {
		if ((defined($data[$i][3]) && ($data[$i][3] == 5))) {	# 5 = fax
			if (defined($data[$i][4]) && ($data[$i][4] ne '-') && ($data[$i][4] > 0)) {	# page > 0
				push(@data_fax, join("\t", @{$data[$i]} ));
			}
		}
	}
	return(\@data_fax);	
}

=pod

=encoding utf8

=head1 NAME

fax2slack.pl - Fax incoming Notifier for Slack <https://github.com/mah-jp/fax2slack>

=head1 VERSION

ver.20170328

=head1 DESCRIPTION

FUJI XEROXの複合機 (動作確認はDocuCentre-IV C2263Nで行いました) の

ウェブ管理画面にある「ジョブ履歴」の内容を実行時にチェックし、

新しいFAX受信があれば、受信時刻と枚数をSlackに通知します。

数分間隔で定期実行されることを前提に作成しました。

実行前には、あらかじめ、INIファイル内に、Slackのwebhook URLや、

複合機のIPアドレスなどの設定を記述しておく必要があります。

=head1 USAGE

fax2slack.pl [-n] [-i INIFILE]

=head2 OPTION

=over

=item [-i INIFILE] (default = fax2slack_test.ini)

=item [-n] (dryrun, default = no)

=back

=head1 AUTHOR

大久保 正彦 (Masahiko OHKUBO) <mah@remoteroom.jp> <https://twitter.com/mah_jp>

勤務先: アイクラフト株式会社 <http://icraft.jp/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Masahiko OHKUBO.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
