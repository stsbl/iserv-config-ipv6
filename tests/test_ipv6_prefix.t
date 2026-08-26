use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

my $tool = 'lib/iserv-ipv6-prefix';
ok(-x $tool, 'prefix query utility is executable') or BAIL_OUT('missing prefix utility');
my $tmp = tempdir(CLEANUP => 1);
my $config = "$tmp/config";
my $state = "$tmp/state";
make_path($config, $state);
open my $dsl, '>', "$config/ipv6-dsl" or die $!;
print {$dsl} "ENABLED=1\nADDRESS_TOKEN=::2\nREQUEST_PREFIX=1\n";
close $dsl;

local %ENV = (%ENV, ISERV_IPV6_DHCP_CONFIG_DIR => $config, ISERV_IPV6_DHCPCD_STATE_DIR => $state);
is(system("./$tool", '--delegation-enabled') >> 8, 1, 'DSL without downstreams does not claim usable delegation');
open my $delegation, '>', "$config/ipv6-delegation-interfaces.list" or die $!;
print {$delegation} "br100\n";
close $delegation;
is(system("./$tool", '--delegation-enabled') >> 8, 0, 'explicit DSL prefix request is exposed through the query utility');

done_testing;
