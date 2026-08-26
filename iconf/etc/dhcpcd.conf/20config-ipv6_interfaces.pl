#!/usr/bin/perl -CSDAL

use warnings;
use strict;
use Path::Tiny;
use List::MoreUtils qw(uniq);

my $config_dir = $ENV{ISERV_IPV6_DHCP_CONFIG_DIR} // '/var/lib/iserv/config';
my $state_dir = $ENV{ISERV_IPV6_DHCPCD_STATE_DIR} // '/var/lib/iserv/config-ipv6/dhcpcd';
my $request_file = "$config_dir/ipv6-dhcp-interfaces.list";
my $delegation_file = "$config_dir/ipv6-delegation-interfaces.list";

sub lines_if_present
{
  my ($file) = @_;
  return () unless -f $file;
  return uniq map { chomp; $_ } path($file)->lines_utf8;
}

my @upstreams = lines_if_present($request_file);
exit 0 unless @upstreams;
my $upstream = shift @upstreams;
my @downstreams = lines_if_present($delegation_file);

print <<'DHCPCD';
duid
noipv6rs
waitip 6
ipv6only

nohook hostname, ntp

option domain_name_servers, domain_name, domain_search
option rapid_commit

slaac token ::2

DHCPCD

print "interface $upstream\n";
print "\tipv6rs\n";
my $request_na = "$state_dir/$upstream.request-na";
print "\tia_na 1\n" if -f $request_na && int(path($request_na)->slurp_utf8);

if (@downstreams)
{
  my $length_file = "$state_dir/$upstream.sla-len";
  my $prefix_length = -f $length_file ? int(path($length_file)->slurp_utf8) : 62;
  my @delegations;
  for my $interface (@downstreams)
  {
    my $sla_file = "$state_dir/$interface.sla-id";
    next unless -f $sla_file;
    my $sla_id = path($sla_file)->slurp_utf8;
    chomp $sla_id;
    next unless $sla_id =~ /^[0-9a-f]+$/i;
    push @delegations, "$interface/" . hex($sla_id) . '/64';
  }
  print "\tia_pd 1/::/$prefix_length @delegations\n" if @delegations;
}
