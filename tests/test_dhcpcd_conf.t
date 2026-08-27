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
my $dsl = "$tmp/ipv6-dsl";
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

sub run_generator {
    local %ENV = (%ENV,
        ISERV_IPV6_DHCP_CONFIG_DIR => $config,
        ISERV_IPV6_DHCPCD_STATE_DIR => "$state/dhcpcd",
        ISERV_IPV6_DSL_CONFIG => $dsl,
    );
    my $stderr = gensym;
    my $pid = open3(undef, my $stdout, $stderr, "./$generator");
    my $output = do { local $/; <$stdout> // '' };
    my $errors = do { local $/; <$stderr> // '' };
    waitpid $pid, 0;
    return ($? >> 8, $output, $errors);
}

my ($exit, $output, $errors) = run_generator();
is($exit, 0, "generator exits successfully: $errors");
like($output, qr/^interface wan0\n\tipv6rs\n\tia_na 1\n\tia_pd 1\/::\/56 br100\/0\/64 br200\/24\/64\n/m,
    'generator emits the regular delegated prefix configuration');

open my $br200_ifid, '>', "$state/dhcpcd/br200.ifid" or die $!;
print {$br200_ifid} "42\n";
close $br200_ifid;
($exit, $output, $errors) = run_generator();
is($exit, 0, "generator accepts an optional delegated interface identifier: $errors");
like($output, qr/^\tia_pd 1\/::\/56 br100\/0\/64 br200\/24\/64\/42$/m,
    'generator renders a configured interface identifier as dhcpcd IA_PD suffix');
unlink "$state/dhcpcd/br200.ifid" or die $!;

open my $request_na, '>', "$state/dhcpcd/wan0.request-na" or die $!;
print {$request_na} "0\n";
close $request_na;
($exit, $output, $errors) = run_generator();
is($exit, 0, "generator accepts an explicit IA_NA opt-out: $errors");
unlike($output, qr/^\tia_na 1$/m, 'explicitly disabled IA_NA is not requested');
unlink "$state/dhcpcd/wan0.request-na" or die $!;

open my $duid, '>', "$state/dhcpcd/duid" or die $!;
print {$duid} "00:01:00:01:29:4f:be:db:18:c0:4d:0d:b9:20\n";
close $duid;
open my $iaid, '>', "$state/dhcpcd/wan0.iaid" or die $!;
print {$iaid} "0\n";
close $iaid;
($exit, $output, $errors) = run_generator();
is($exit, 0, "generator accepts migrated DHCPv6 client identity: $errors");
like($output, qr/^duid 00:01:00:01:29:4f:be:db:18:c0:4d:0d:b9:20$/m,
    'generator emits the migrated WIDE DUID');
like($output, qr/^\tia_pd 0\/::\/56 br100\/0\/64 br200\/24\/64$/m,
    'generator preserves the WIDE IA_PD IAID');
unlink "$state/dhcpcd/duid" or die $!;
unlink "$state/dhcpcd/wan0.iaid" or die $!;

open my $dsl_config, '>', $dsl or die $!;
print {$dsl_config} "ENABLED=1\nADDRESS_TOKEN=::2\nREQUEST_PREFIX=1\nREQUEST_NA=0\nSLA_LEN=56\n";
close $dsl_config;
($exit, $output, $errors) = run_generator();
is($exit, 0, "DSL generator exits successfully: $errors");
like($output, qr/^interface dsl\n\tipv6rs\n\tia_pd 1\/::\/56 br100\/0\/64 br200\/24\/64\n/m,
    'generator prefers explicitly enabled DSL IPv6 for delegated-prefix configuration');
unlike($output, qr/^interface wan0\n/m, 'generator does not retain another prefix-requesting interface when DSL is explicit');

done_testing;
