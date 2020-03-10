#!/bin/bash

echo "Check /etc/default/wide-dhcpv6-client"
echo "Check /etc/wide-dhcpv6/dhcp6c-script"
echo "ChPerm 0755 root:root /etc/wide-dhcpv6/dhcp6c-script"
echo "MkDir 0755 root:root /etc/iserv/config-ipv6"
echo "MkDir 0755 root:root /etc/iserv/config-ipv6/wide-dhcp-post-start.d"
echo

if [ -s /var/lib/iserv/config/ipv6-dhcp-interfaces.list ]
then
  echo "Check /etc/wide-dhcpv6/dhcp6c.conf"
  echo "Reload wide-dhcpv6-client"
  echo "Enable iserv-wide-dhcpv6-wait"
else
  echo "Remove /etc/wide-dhcpv6/dhcp6c.conf"
  echo "Stop wide-dhcpv6-client"
  echo "Disable iserv-wide-dhcpv6-wait"
fi
echo
