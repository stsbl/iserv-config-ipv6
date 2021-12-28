#!/usr/bin/perl -CSDAL

use warnings;
use strict;
use Path::Tiny;
use List::MoreUtils qw(uniq);

my $fn_prefix = "/etc/iserv/dhcpv6-prefix";
my $fn_request_interface = "/var/lib/iserv/config/ipv6-dhcp-interfaces.list";
my $fn_delegation_interface = "/var/lib/iserv/config/ipv6-delegation-interfaces.list";

my $prefix_len = 62;

if (-f $fn_prefix)
{
  $prefix_len = path($fn_prefix)->slurp_utf8;
  chomp $prefix_len;
}

my @interfaces = uniq map { chomp $_; $_; }
    path($fn_request_interface)->lines_utf8;

for (@interfaces)
{
  print <<EOT;
interface $_ {
	send ia-pd 0;
	send rapid-commit;

	request domain-name-servers;
	request domain-name;

	script "/etc/wide-dhcpv6/dhcp6c-script";
};

EOT
}

my @delegation_interfaces = uniq map { chomp $_; $_; }
    path($fn_delegation_interface)->lines_utf8;

if (@interfaces and @delegation_interfaces)
{
  print <<EOT;
id-assoc pd 0 {
	prefix ::/$prefix_len infinity;
EOT

  my $id = 0;
  for (@delegation_interfaces)
  {
    my $len = 128 - 64 - $prefix_len;
    print <<EOT;
	prefix-interface $_ {
		sla-id $id;
		sla-len $len;
	};
EOT
    $id++;
  }
  
  print "};\n\n"
}
