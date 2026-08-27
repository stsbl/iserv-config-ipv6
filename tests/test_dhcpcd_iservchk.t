use strict;
use warnings;
use Test::More;
use Path::Tiny;

my $script = 'iservchk/12dhcpcd/20config-ipv6.sh';
ok(-x $script, 'dhcpcd iservchk generator exists') or BAIL_OUT('missing dhcpcd iservchk generator');
ok(!-e 'iservchk/11dhcpcd/20config-ipv6.sh', 'legacy pre-network dhcpcd check is absent');

my $source = path($script)->slurp_utf8;
like($source, qr/Check \/etc\/dhcpcd\.conf/, 'manages generated dhcpcd configuration');
like($source, qr/Start dhcpcd dhcpcd/, 'starts dhcpcd through iservchk');
like($source, qr/iserv-ipv6-sync-ifupdown-state/, 'synchronizes ifupdown state before evaluating dhcpcd checks');
like($source, qr/Remove \/etc\/wide-dhcpv6\/dhcp6c\.conf/, 'removes obsolete WIDE configuration');
like($source, qr/Stop wide-dhcpv6-client/, 'stops obsolete WIDE client');
like($source, qr/else\n  echo \"Remove \/etc\/dhcpcd\.conf\"\n  echo \"Stop dhcpcd\"/, 'stops native dhcpcd only when IPv6 delegation is unused');
done_testing;
