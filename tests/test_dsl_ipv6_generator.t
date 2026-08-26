use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use IPC::Open3;
use Symbol qw(gensym);

my $generator = 'lib/iserv-ipv6-dsl';
ok(-x $generator, 'DSL IPv6 peer generator is executable')
    or BAIL_OUT('DSL IPv6 peer generator is missing');

my $tmp = tempdir(CLEANUP => 1);
my $peer = "$tmp/dsl";
my $config = "$tmp/ipv6-dsl";
open my $fh, '>', $peer or die $!;
print {$fh} "plugin rp-pppoe.so enp35s0\nuser \"example\"\n";
close $fh;
open $fh, '>', $config or die $!;
print {$fh} "ENABLED=1\nADDRESS_TOKEN=::2\nREQUEST_PREFIX=1\n";
close $fh;

sub run_generator {
    my (@arguments) = @_;
    local %ENV = (%ENV, ISERV_IPV6_DSL_PEER => $peer, ISERV_IPV6_DSL_CONFIG => $config);
    my $stderr = gensym;
    my $pid = open3(undef, my $stdout, $stderr, "./$generator", @arguments);
    my $output = do { local $/; <$stdout> // '' };
    my $errors = do { local $/; <$stderr> // '' };
    waitpid $pid, 0;
    return ($? >> 8, $output, $errors);
}

is((run_generator('--apply'))[0], 0, 'generator applies the enabled DSL IPv6 configuration');
is((run_generator('--check'))[0], 0, 'generator verifies its generated DSL IPv6 block');
open $fh, '<', $peer or die $!;
my $output = do { local $/; <$fh> };
close $fh;
like($output, qr/# BEGIN stsbl-iserv-config-ipv6 DSL IPv6\n\+ipv6\nipv6 ::2\nifname dsl\n# END stsbl-iserv-config-ipv6 DSL IPv6\n\z/,
    'generator appends an idempotent managed IPv6 block');

open $fh, '>', $config or die $!;
print {$fh} "ENABLED=0\nADDRESS_TOKEN=::2\nREQUEST_PREFIX=1\n";
close $fh;
is((run_generator('--apply'))[0], 0, 'generator accepts disabled IPv6');
open $fh, '<', $peer or die $!;
$output = do { local $/; <$fh> };
close $fh;
unlike($output, qr/stsbl-iserv-config-ipv6 DSL IPv6/, 'generator removes its block when IPv6 is disabled');

done_testing;
