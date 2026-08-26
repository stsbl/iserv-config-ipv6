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

done_testing;
