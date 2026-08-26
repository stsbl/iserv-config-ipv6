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

open my $request_na, '>', "$state/dhcpcd/wan0.request-na" or die $!;
print {$request_na} "0\n";
close $request_na;
($exit, $output, $errors) = run_generator();
is($exit, 0, "generator accepts an explicit IA_NA opt-out: $errors");
unlike($output, qr/^\tia_na 1$/m, 'explicitly disabled IA_NA is not requested');
unlink "$state/dhcpcd/wan0.request-na" or die $!;

open my $dsl_config, '>', $dsl or die $!;
print {$dsl_config} "ENABLED=1\nADDRESS_TOKEN=::2\nREQUEST_PREFIX=1\n";
close $dsl_config;
($exit, $output, $errors) = run_generator();
is($exit, 0, "DSL generator exits successfully: $errors");
like($output, qr/^interface dsl\n\tipv6rs\n\tia_na 1\n\tia_pd 1\/::\/62 br100\/0\/64 br200\/24\/64\n/m,
    'generator prefers explicitly enabled DSL IPv6 for delegated-prefix configuration');
unlike($output, qr/^interface wan0\n/m, 'generator does not retain another prefix-requesting interface when DSL is explicit');

done_testing;
