use strict;
use warnings;
use Test::More;
use Path::Tiny;

my $migration = 'iservchk/80legacy/30config-ipv6_remove-wide-dhcpv6';
ok(-f $migration, 'WIDE DHCPv6 removal migration exists')
    or BAIL_OUT('missing WIDE DHCPv6 removal migration');
my $content = path($migration)->slurp_utf8;
like($content, qr/iservpkginstalled wide-dhcpv6-client/,
    'checks package installation state through IServ helper');
like($content, qr/apt-get -y purge wide-dhcpv6-client/, 'purges the obsolete WIDE DHCPv6 client');

done_testing;
