#!/usr/bin/perl -CSDAL

use warnings;
use strict;
use Path::Tiny;
use List::MoreUtils qw(uniq);

my $fn_prefix = "/etc/iserv/dhcpv6-prefix";
my $fn_request_interface = "/var/lib/iserv/config/ipv6-dhcp-interfaces.list";
my $fn_delegation_interface = "/var/lib/iserv/config/ipv6-delegation-interfaces.list";

my $prefix_len = 62;

my @interfaces = uniq map { chomp $_; $_; }
    path($fn_request_interface)->lines_utf8;
exit 0 unless @interfaces;

my $upstream_interface = shift @interfaces;

my $request_na = 1;
my $fn_request_na = "/var/lib/iserv/config-ipv6/wide-dhcpv6-client/$upstream_interface.request-na";
if (-f $fn_request_na)
{
  $request_na = path($fn_request_na)->slurp_utf8;
  $request_na = int $request_na;
}

my $send_ia_na = $request_na ? "\n\tsend ia-na 0;" : "";

print <<EOT;
interface $upstream_interface {
	send ia-pd 0;$send_ia_na
	send rapid-commit;

	request domain-name-servers;
	request domain-name;

	script "/etc/wide-dhcpv6/dhcp6c-script";
};

EOT

print <<EOT if $request_na;
id-assoc na 0 {
};

EOT

my @delegation_interfaces = uniq map { chomp $_; $_; }
    path($fn_delegation_interface)->lines_utf8;

if ($upstream_interface and @delegation_interfaces)
{
  my $fn_sla_len = "/var/lib/iserv/config-ipv6/wide-dhcpv6-client/$upstream_interface.sla-len";
  if (-f $fn_sla_len)
  {
    $prefix_len = path($fn_sla_len)->slurp_utf8;
    chomp $prefix_len;
  }

  print <<EOT;
id-assoc pd 0 {
	prefix ::/$prefix_len infinity;
EOT

  for (@delegation_interfaces)
  {
    my $fn_sla_id = "/var/lib/iserv/config-ipv6/wide-dhcpv6-client/$_.sla-id";
    my $fn_ifid = "/var/lib/iserv/config-ipv6/wide-dhcpv6-client/$_.ifid";

    -f $fn_sla_id or next;
    my $sla_id = path($fn_sla_id)->slurp_utf8;
    chomp $sla_id;

    my $len = 128 - 64 - $prefix_len;
    print <<EOT;
	prefix-interface $_ {
		sla-id $sla_id;
		sla-len $len;
EOT
    if (-f $fn_ifid)
    {
      my $ifid = path($fn_ifid)->slurp_utf8;
      chomp $ifid;
      $ifid = hex($ifid) or die "hex ifid: $!\n";
      print <<EOT;
		ifid $ifid;
EOT
    }
    print <<EOT
	};
EOT
  }

  print "};\n\n"
}
