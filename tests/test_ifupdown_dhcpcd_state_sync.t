use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

my $sync = 'lib/iserv-ipv6-sync-ifupdown-state';
ok(-x $sync, 'ifupdown dhcpcd state synchronizer is executable')
    or BAIL_OUT('missing ifupdown dhcpcd state synchronizer');

my $tmp = tempdir(CLEANUP => 1);
my $config = "$tmp/config";
my $state = "$tmp/state";
my $interfaces = "$tmp/ipv6";
make_path($config, $state);

open my $fh, '>', "$config/ipv6-dhcp-interfaces.list" or die $!;
print {$fh} "wan0\n";
close $fh;
open $fh, '>', "$config/ipv6-delegation-interfaces.list" or die $!;
print {$fh} "lan0\n";
close $fh;
open $fh, '>', $interfaces or die $!;
print {$fh} <<'INTERFACES';
iface wan0 inet6 manual
    dhcpcd-sla-len 60
    dhcpcd-request-na 0

iface lan0 inet6 manual
    wide-dhcpv6-sla-id 1
    wide-dhcpv6-ifid 42
INTERFACES
close $fh;

local %ENV = (%ENV,
    ISERV_IPV6_DHCP_CONFIG_DIR => $config,
    ISERV_IPV6_DHCPCD_STATE_DIR => $state,
    ISERV_IPV6_INTERFACES_FILE => $interfaces,
);
isnt(system("./$sync") >> 8, 0, 'state synchronizer reports missing state without repairing it');
ok(!-e "$state/wan0.sla-len", 'check mode does not write state');
is(system("./$sync", '--repair') >> 8, 0, 'state synchronizer repairs missing state');

for my $expected (
    ['wan0.sla-len', '60'], ['wan0.request-na', '0'],
    ['lan0.sla-id', '1'], ['lan0.ifid', '42'],
) {
    my $path = "$state/$expected->[0]";
    ok(-f $path, "writes $expected->[0]");
    next unless -f $path;
    open my $state_fh, '<', $path or die $!;
    chomp(my $value = <$state_fh>);
    is($value, $expected->[1], "syncs $expected->[0] from ifquery");
}

unlink $interfaces or die $!;
open $fh, '>', $interfaces or die $!;
print {$fh} <<'INTERFACES';
iface wan0 inet6 manual
    dhcpcd-sla-len 56

iface lan0 inet6 manual
    dhcpcd-sla-id 2
INTERFACES
close $fh;
isnt(system("./$sync") >> 8, 0, 'state synchronizer detects configuration updates');
is(system("./$sync", '--repair') >> 8, 0, 'state synchronizer repairs configuration updates');
open my $updated_fh, '<', "$state/wan0.sla-len" or die $!;
chomp(my $updated_value = <$updated_fh>);
is($updated_value, '56', 'updates existing state from ifquery');
ok(!-e "$state/wan0.request-na", 'removes state for an absent optional upstream setting');
ok(!-e "$state/lan0.ifid", 'removes state for an absent optional interface identifier');

done_testing;
