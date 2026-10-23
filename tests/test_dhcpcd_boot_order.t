use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Path::Tiny;

my $tmp = tempdir(CLEANUP => 1);
path("$tmp/systemctl")->spew_utf8(<<'SH');
#!/bin/sh
# A synchronous request would wait for the network service running this hook.
case " $* " in
  *' --no-block try-restart dhcpcd.service '*) exit 0 ;;
  *) exit 42 ;;
esac
SH
path("$tmp/grep")->spew_utf8("#!/bin/sh\nexit 0\n");
chmod 0755, "$tmp/systemctl", "$tmp/grep";
local $ENV{PATH} = "$tmp:$ENV{PATH}";
local @ENV{qw(PHASE ADDRFAM METHOD IFACE)} = qw(post-up inet6 manual lan0);

for my $hook (
    'iconf/etc/network/if-up.d/zzz_iserv-ipv6/30config-ipv6',
    'iconf/etc/ppp/ip-up.d/iserv/80config-ipv6',
) {
    # set -e also catches a failed command hidden by the final status message.
    system('sh', '-e', $hook);
    is($? >> 8, 0, "$hook requests a nonblocking restart only if dhcpcd is running");
}

my $ppp = path('iconf/etc/network/if-up.d/iserv/60config-ipv6_ppp')->slurp_utf8;
my @restarts = $ppp =~ /^(\s*systemctl[^\n]*restart[^\n]*)/mg;
is(scalar @restarts, 2, 'both PPP accept_ra restart paths are covered');
like($_, qr/--no-block try-restart dhcpcd\.service/, 'PPP restart is nonblocking and preserves a stopped dhcpcd') for @restarts;

my $dropin = 'systemd/dhcpcd.service.d/config-ipv6.conf';
ok(-f $dropin, 'static ordering drop-in is packaged under lib/systemd/system');
if (-f $dropin) {
    my $unit = path($dropin)->slurp_utf8;
    like($unit, qr/^After=network\.target$/m, 'dhcpcd waits for ifupdown completion');
    like($unit, qr/^Before=network-online\.target$/m, 'online waits for dhcpcd start completion');
}
my $check = path('iservchk/12dhcpcd/20config-ipv6.sh')->slurp_utf8;
like($check, qr{Link /lib/systemd/system/dhcpcd\.service /etc/systemd/system/network-online\.target\.requires/dhcpcd\.service},
    'online requires dhcpcd when prefix delegation is configured');
like($check, qr{Remove /etc/systemd/system/network-online\.target\.requires/dhcpcd\.service},
    'online does not start dhcpcd when prefix delegation is unused');

done_testing;
