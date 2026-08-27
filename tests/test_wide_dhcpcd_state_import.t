use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Path::Tiny;

my $importer = 'lib/iserv-ipv6-import-wide-state';
ok(-x $importer, 'legacy WIDE state importer is executable')
    or BAIL_OUT('legacy WIDE state importer is missing');

my $tmp = tempdir(CLEANUP => 1);
my $config = "$tmp/config";
my $state = "$tmp/state";
my $interfaces = "$tmp/ipv6";
my $wide_duid = "$tmp/dhcp6c_duid";
make_path($config, $state);
open my $duid_fh, '>:raw', $wide_duid or die $!;
print {$duid_fh} pack('C*', 0x0e, 0x00, 0x01, 0x00, 0x01, 0x29, 0x4f, 0xbe, 0xdb, 0x18, 0xc0, 0x4d, 0x0d, 0xb9, 0x20);
close $duid_fh;
open my $fh, '>', "$config/ipv6-dhcp-interfaces.list" or die $!;
print {$fh} "wan0\n";
close $fh;
open $fh, '>', "$config/ipv6-delegation-interfaces.list" or die $!;
print {$fh} "lan0\nlan1\n";
close $fh;
open $fh, '>', $interfaces or die $!;
print {$fh} <<'INTERFACES';
iface wan0 inet6 manual
    wide-dhcpv6-sla-len 60

iface lan0 inet6 manual
    wide-dhcpv6-sla-id 0
    wide-dhcpv6-ifid 1

iface lan1 inet6 manual
    wide-dhcpv6-sla-id 1
    wide-dhcpv6-ifid 1
INTERFACES
close $fh;

local %ENV = (%ENV,
    ISERV_IPV6_DHCP_CONFIG_DIR => $config,
    ISERV_IPV6_DHCPCD_STATE_DIR => $state,
    ISERV_IPV6_WIDE_DUID_FILE => $wide_duid,
);
isnt(system("./$importer") >> 8, 0, 'legacy import reports missing state without repairing it');
ok(!-e "$state/duid", 'check mode does not create the DUID state');
is(system("./$importer", '--repair') >> 8, 0, 'legacy import repairs missing state');
for my $expected (
    ['duid', '00:01:00:01:29:4f:be:db:18:c0:4d:0d:b9:20'],
    ['wan0.iaid', '0'],
) {
    my $state_path = "$state/$expected->[0]";
    ok(-f $state_path, "imports $expected->[0]");
    next unless -f $state_path;
    open my $state_file, '<', $state_path or die $!;
    chomp(my $value = <$state_file>);
    is($value, $expected->[1], "has expected $expected->[0] value");
}

is(system("./$importer") >> 8, 0, 'legacy import check passes after repair');

my $iservchk = 'iservchk/11network/20config-ipv6';
open my $check_fh, '<', $iservchk or die $!;
my $check_content = do { local $/; <$check_fh> };
close $check_fh;
unlike($check_content, qr{iserv-ipv6-import-wide-state}, 'network checks do not import state after dhcpcd has run');
unlike(path($importer)->slurp_utf8, qr/awk/, 'legacy identity importer does not scrape ifupdown configuration');

my $dhcpcd_check = 'iservchk/12dhcpcd/20config-ipv6.sh';
ok(-x $dhcpcd_check, 'dhcpcd check generator exists');
open $check_fh, '<', $dhcpcd_check or die $!;
$check_content = do { local $/; <$check_fh> };
close $check_fh;
unlike($check_content,
    qr{\A#!/bin/sh\n\n/usr/lib/iserv/iserv-ipv6-(?:import-wide-state|sync-ifupdown-state)},
    'dhcpcd check generator does not mutate state while generating checks');
like($check_content,
    qr{Test "import WIDE DHCPv6 delegation state"\n  /usr/lib/iserv/iserv-ipv6-import-wide-state\n  ---\n  /usr/lib/iserv/iserv-ipv6-import-wide-state --repair},
    'generated iservchk imports the legacy WIDE state through a repair action');
like($check_content,
    qr{Test "synchronize DHCPv6 state from ifupdown"\n  /usr/lib/iserv/iserv-ipv6-sync-ifupdown-state\n  ---\n  /usr/lib/iserv/iserv-ipv6-sync-ifupdown-state --repair},
    'generated iservchk synchronizes ifupdown state through a repair action');
like($check_content, qr{wide-dhcpv6-\(sla-len\|sla-id\|ifid\)}, 'dhcpcd check generator detects legacy WIDE delegation settings');
like($check_content,
    qr{\{ ! \[ -s /var/lib/iserv/config/ipv6-dhcp-interfaces\.list \] \|\|\n    ! grep -Eq},
    'generated iservchk determines the WIDE restart condition at runtime');
like($check_content, qr{systemctl restart dhcpcd\.service}, 'dhcpcd check generator restarts dhcpcd after importing state');
like($check_content, qr{20config-ipv6_restart-wide-dhcpcd}, 'dhcpcd restart is recorded as a one-time migration');

my $generated = qx{sh "$dhcpcd_check" 2>&1};
is($? >> 8, 0, 'dhcpcd check generator executes successfully');
unlike($generated, qr{command not found}, 'dhcpcd check generator emits all checks instead of executing them');
like($generated, qr{Test "restart dhcpcd after importing WIDE DHCPv6 delegation state"},
    'dhcpcd check generator emits the runtime WIDE restart check');

done_testing;
