use strict;
use warnings;
use Test::More;

my $menu = 'share/iservcfg/12dsl6';
ok(-x $menu, 'DSL IPv6 menu is executable') or BAIL_OUT('missing DSL IPv6 menu');
open my $fh, '<', $menu or die $!;
my $source = do { local $/; <$fh> };
close $fh;
like($source, qr/DSL ist nicht aktiviert/, 'menu explains that base DSL must be activated first');
like($source, qr/iservcfg dsl/, 'menu offers to invoke the base DSL configuration');
like($source, qr/REQUEST_NA=1/, 'IA_NA is requested by default');
like($source, qr/SLA_LEN=62/, 'delegated prefix length defaults to /62');
like($source, qr/request_na\s+"IA_NA-Adresse anfordern:/, 'menu exposes the IA_NA setting');
like($source, qr/sla_len\s+"Delegierte Präfixlänge:/, 'menu exposes the delegated prefix length');
like($source, qr/^REQUEST_NA=\$REQUEST_NA$/m, 'menu persists the IA_NA setting');
like($source, qr/^SLA_LEN=\$SLA_LEN$/m, 'menu persists the delegated prefix length');
like($source, qr/valid_prefix_length\(\) \{ \[\[ "\$1" =~ \^\[0-9\]\+\$/, 'prefix length accepts numeric input only');

done_testing;
