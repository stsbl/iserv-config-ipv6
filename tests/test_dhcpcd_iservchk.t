use strict;
use warnings;
use Test::More;
use Path::Tiny;

my $script = 'iservchk/11dhcpcd/20config-ipv6.sh';
ok(-x $script, 'dhcpcd iservchk generator exists') or BAIL_OUT('missing dhcpcd iservchk generator');
my $source = path($script)->slurp_utf8;
like($source, qr/Check \/etc\/dhcpcd\.conf/, 'manages generated dhcpcd configuration');
like($source, qr/Start dhcpcd dhcpcd/, 'starts dhcpcd through iservchk');
like($source, qr/Remove \/etc\/wide-dhcpv6\/dhcp6c\.conf/, 'removes obsolete WIDE configuration');
like($source, qr/Stop wide-dhcpv6-client/, 'stops obsolete WIDE client');
done_testing;
