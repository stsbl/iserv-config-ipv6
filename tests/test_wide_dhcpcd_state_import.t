use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

my $importer = 'lib/iserv-ipv6-import-wide-state';
ok(-x $importer, 'legacy WIDE state importer is executable')
    or BAIL_OUT('legacy WIDE state importer is missing');

my $tmp = tempdir(CLEANUP => 1);
my $config = "$tmp/config";
my $state = "$tmp/state";
my $interfaces = "$tmp/ipv6";
make_path($config, $state);
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
    ISERV_IPV6_INTERFACES_FILE => $interfaces,
);
is(system("./$importer") >> 8, 0, 'legacy import exits successfully');
for my $expected (
    ['wan0.sla-len', '60'],
    ['lan0.sla-id', '0'], ['lan0.ifid', '1'],
    ['lan1.sla-id', '1'], ['lan1.ifid', '1'],
) {
    open my $state_file, '<', "$state/$expected->[0]" or die $!;
    chomp(my $value = <$state_file>);
    is($value, $expected->[1], "imports $expected->[0]");
}

my $iservchk = 'iservchk/11network/20config-ipv6';
open my $check_fh, '<', $iservchk or die $!;
my $check_content = do { local $/; <$check_fh> };
close $check_fh;
unlike($check_content, qr{iserv-ipv6-import-wide-state}, 'network checks do not import state after dhcpcd has run');

my $dhcpcd_check = 'iservchk/11dhcpcd/20config-ipv6.sh';
ok(-x $dhcpcd_check, 'dhcpcd check generator exists');
open $check_fh, '<', $dhcpcd_check or die $!;
$check_content = do { local $/; <$check_fh> };
close $check_fh;
like($check_content,
    qr{\A#!/bin/sh\n\n/usr/lib/iserv/iserv-ipv6-import-wide-state\n\nif \[ -s},
    'dhcpcd check generator imports the legacy WIDE state before generating checks');

done_testing;
