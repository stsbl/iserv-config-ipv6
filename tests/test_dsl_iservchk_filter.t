use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

my $filter = 'iconf/etc/iserv/chk.d/11network/90config-ipv6_dsl.sed';
ok(-f $filter, 'DSL interface filter exists')
    or BAIL_OUT('missing DSL interface filter');

my ($input_fh, $input) = tempfile();
print {$input_fh} <<'CHECKS';
Shell "dsl: interface ppp up"
  ! dsl || ifconfig|grep -q ^ppp
Shell "dsl: default route set"
  ! dsl || LC_ALL=C route -n | awk '$1=="0.0.0.0" && $8~/^ppp/' | grep -q .
CHECKS
close $input_fh;

my $output = `sed -f "$filter" "$input"`;
is($? >> 8, 0, 'filter exits successfully');
like($output, qr/ifconfig \| grep -q '\^dsl:'/,
    'filter checks the static DSL interface name');
like($output, qr/\$8~\/\^dsl\$\//,
    'filter checks the default route on the static DSL interface name');
unlike($output, qr/\^ppp/, 'filter removes dynamic PPP interface matching');

done_testing;
