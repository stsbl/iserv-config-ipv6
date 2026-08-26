use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use IPC::Open3;
use Symbol qw(gensym);

my $generator = 'iconf/etc/dhcpcd.conf/20config-ipv6_interfaces.pl';
ok(-x $generator, 'dhcpcd configuration generator is installed as an executable iconf fragment')
    or BAIL_OUT('dhcpcd configuration generator is missing');

my $tmp = tempdir(CLEANUP => 1);
my $config = "$tmp/config";
my $state = "$tmp/state";
make_path($config, $state);
open my $dhcp, '>', "$config/ipv6-dhcp-interfaces.list" or die $!;
print {$dhcp} "wan0\n";
close $dhcp;
open my $delegation, '>', "$config/ipv6-delegation-interfaces.list" or die $!;
print {$delegation} "br100\nbr200\n";
close $delegation;
make_path("$state/dhcpcd");
open my $length, '>', "$state/dhcpcd/wan0.sla-len" or die $!;
print {$length} "56\n";
close $length;
open my $br100, '>', "$state/dhcpcd/br100.sla-id" or die $!;
print {$br100} "0\n";
close $br100;
open my $br200, '>', "$state/dhcpcd/br200.sla-id" or die $!;
print {$br200} "18\n";
close $br200;

local %ENV = (%ENV,
    ISERV_IPV6_DHCP_CONFIG_DIR => $config,
    ISERV_IPV6_DHCPCD_STATE_DIR => "$state/dhcpcd",
);
my $stderr = gensym;
my $pid = open3(undef, my $stdout, $stderr, "./$generator");
my $output = do { local $/; <$stdout> // '' };
my $errors = do { local $/; <$stderr> // '' };
waitpid $pid, 0;
is($? >> 8, 0, "generator exits successfully: $errors");
like($output, qr/^interface wan0\n\tipv6rs\n\tia_pd 1\/::\/56 br100\/0\/64 br200\/24\/64\n/m,
    'generator emits the pve00-style delegated prefix configuration');

done_testing;
