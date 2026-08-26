#!/bin/sh

if [ -s /var/lib/iserv/config/ipv6-dhcp-interfaces.list ]
then
  echo "Check /etc/dhcpcd.conf"
  echo "Start dhcpcd dhcpcd"
else
  echo "Remove /etc/dhcpcd.conf"
  echo "Stop dhcpcd"
fi

echo "Remove /etc/default/wide-dhcpv6-client"
echo "Remove /etc/wide-dhcpv6/dhcp6c.conf"
echo "Remove /etc/wide-dhcpv6/dhcp6c-script"
echo "Stop wide-dhcpv6-client"
echo "Disable iserv-wide-dhcpv6-wait"
echo
