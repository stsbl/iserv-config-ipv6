package Stsbl::IServ::Net::IPv6;

use warnings;
use strict;
use Net::IP;

BEGIN
{
  use Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(ip_to_raw raw_to_ip raw_prefix_from_ip raw_suffix_from_ip
      ip_to_prefix ip_to_suffix join_prefix_and_suffix);
}

sub ip_to_raw($)
{
  my ($ip) = @_;
  $ip = Net::IP::ip_expand_address($ip, 6); 
  my $raw = unpack("B*", pack("H*", join "", split /:/, $ip));

  $raw;
}

sub raw_to_ip($)
{
  my ($raw) = @_;
  my $ip = join(":", unpack("(A4)*", unpack("H*", pack("B*", $raw))));
  $ip = Net::IP::ip_compress_address $ip, 6;

  $ip;
}

sub raw_prefix_from_ip($$)
{
  my ($ip, $length) = @_;
  my $raw = ip_to_raw $ip;
  my $raw_prefix = substr($raw, 0, -$length);

  $raw_prefix;
}

sub raw_suffix_from_ip($$)
{
  my ($ip, $length) = @_;
  my $raw = ip_to_raw $ip;
  my $raw_suffix = substr($raw, -$length);

  $raw_suffix;
}

sub ip_to_prefix($$)
{
  my ($ip, $length) = @_;
  my $raw_prefix = raw_prefix_from_ip $ip, $length;

  my $prefix_length = 128 - $length;
  $raw_prefix .= 0 for 1..$prefix_length;

  $ip = raw_to_ip $raw_prefix;
  $ip =~ s/::$//g;

  $ip;
}

sub ip_to_suffix($$)
{
  my ($ip, $length) = @_;
  my $raw_suffix = raw_suffix_from_ip $ip, $length;

  my $raw_prefix;
  my $suffix_length = 128 - $length;
  $raw_prefix .= 0 for 1..$suffix_length;

  $ip = raw_to_ip $raw_prefix . $raw_suffix;
  $ip =~ s/^:://g;

  $ip;
}

sub join_prefix_and_suffix($$$$)
{
  my ($prefix, $prefix_length, $suffix, $suffix_length) = @_;

  die "Lnegth of prefix and suffix together must give 128!\n"
      unless $prefix_length + $suffix_length == 128;

  my $raw = raw_prefix_from_ip($prefix, $prefix_length) .
      raw_suffix_from_ip($suffix, $suffix_length);
  my $ip = raw_to_ip $raw;

  $ip;
}
1;
