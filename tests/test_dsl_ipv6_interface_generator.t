use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use IPC::Open3;
use Symbol qw(gensym);
use Path::Tiny;

my $generator = 'lib/iserv-ipv6-dsl-interface';
ok(-x $generator, 'DSL ifupdown generator is executable')
    or BAIL_OUT('missing DSL ifupdown generator');

my $tmp = tempdir(CLEANUP => 1);
my $config = "$tmp/ipv6-dsl";
my $interfaces = "$tmp/interfaces.d/ipv6";
my $config_dir = "$tmp/config";
make_path($config_dir);

sub run_generator {
    my (@arguments) = @_;
    local %ENV = (%ENV,
        ISERV_IPV6_DSL_CONFIG => $config,
        ISERV_IPV6_INTERFACES_FILE => $interfaces,
        ISERV_IPV6_DHCP_CONFIG_DIR => $config_dir,
    );
    my $stderr = gensym;
    my $pid = open3(undef, my $stdout, $stderr, "./$generator", @arguments);
    my $output = do { local $/; <$stdout> // '' };
    my $errors = do { local $/; <$stderr> // '' };
    waitpid $pid, 0;
    return ($? >> 8, $output, $errors);
}

path($config)->spew_utf8("ENABLED=1\nREQUEST_PREFIX=1\nREQUEST_NA=0\nSLA_LEN=56\n");
path("$config_dir/ipv6-dhcp-interfaces.list")->spew_utf8("wan0\n");
is((run_generator('--apply'))[0], 0, 'writes enabled DSL IPv6 configuration');
is((run_generator('--check'))[0], 0, 'generated DSL IPv6 configuration is current');
my $output = path($interfaces)->slurp_utf8;
like($output, qr/# BEGIN stsbl-iserv-config-ipv6 DSL DHCPv6\niface dsl inet6 manual\n\tdhcpcd-request-na 0\n\tdhcpcd-sla-len 56\n# END stsbl-iserv-config-ipv6 DSL DHCPv6/s,
    'writes the static DSL interface stanza with dhcpcd options');
is(path("$config_dir/ipv6-dhcp-interfaces.list")->slurp_utf8, "dsl\nwan0\n",
    'declares DSL as the dhcpcd upstream for prefix delegation');

path($config)->spew_utf8("ENABLED=1\nREQUEST_PREFIX=0\nREQUEST_NA=1\nSLA_LEN=62\n");
is((run_generator('--apply'))[0], 0, 'updates DSL IPv6 without a requested prefix');
$output = path($interfaces)->slurp_utf8;
like($output, qr/dhcpcd-request-na 1/, 'keeps DSL IA_NA setting in its stanza');
unlike(path("$config_dir/ipv6-dhcp-interfaces.list")->slurp_utf8, qr/^dsl$/m,
    'does not declare DSL as delegation upstream when prefix requests are disabled');

path($config)->spew_utf8("ENABLED=0\nREQUEST_PREFIX=1\nREQUEST_NA=1\nSLA_LEN=62\n");
is((run_generator('--apply'))[0], 0, 'removes disabled DSL IPv6 configuration');
unlike(path($interfaces)->slurp_utf8, qr/stsbl-iserv-config-ipv6 DSL DHCPv6/,
    'removes the managed DSL stanza when IPv6 is disabled');
unlike(path("$config_dir/ipv6-dhcp-interfaces.list")->slurp_utf8, qr/^dsl$/m,
    'removes DSL from the dhcpcd upstream list when IPv6 is disabled');

done_testing;
