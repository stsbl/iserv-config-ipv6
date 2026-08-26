#!/bin/sh

wide_state_changed="$(/usr/lib/iserv/iserv-ipv6-import-wide-state --changed)"

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

if [ -n "$wide_state_changed" ]
then
  cat <<'EOF'
Test "restart dhcpcd after importing WIDE DHCPv6 delegation state"
  false
  ---
  systemctl restart dhcpcd.service

EOF
fi

echo
