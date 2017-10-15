#!/bin/bash

echo "Check /etc/default/wide-dhcpv6-client"

if [ -s /var/lib/iserv/config/ipv6-dhcp-interfaces.list ]
then
  echo "Check /etc/wide-dhcpv6/dhcp6c.conf"
  echo "Start wide-dhcpv6-client"
else
  echo "Remove /etc/wide-dhcpv6/dhcp6c.conf"
  echo "Stop wide-dhcpv6-client"
fi
echo
