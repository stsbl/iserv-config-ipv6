use strict;
use warnings;
use Test::More;
use Path::Tiny;

my $source = path('share/iservcfg/10network6')->slurp_utf8;
like($source, qr/sub canonical_dhcpv6_mode/, 'normalizes legacy DHCPv6 modes');
like($source, qr/widedhcp.*dhcpcd/s, 'maps legacy widedhcp mode to dhcpcd');
like($source, qr/delg.*dhcpcd-delegation/s, 'maps legacy delg mode to dhcpcd delegation');
like($source, qr/\$option =~ s\/\^wide-dhcpv6-\/dhcpcd-\//, 'maps legacy DHCPv6 option prefix to the canonical dhcpcd prefix');
like($source, qr/dhcpcd-sla-len/, 'writes canonical dhcpcd prefix length option');
like($source, qr/elsif \(\$sel eq \"dsl\" and exists \$conf\{dsl\}\).*?iservcfg\", \"dsl6\"/s, 'redirects DSL IPv6 configuration to iservcfg dsl6');
done_testing;
