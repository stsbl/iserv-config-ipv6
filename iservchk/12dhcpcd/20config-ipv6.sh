#!/bin/sh

cat <<'EOF'
Test "import WIDE DHCPv6 delegation state"
  /usr/lib/iserv/iserv-ipv6-import-wide-state
  ---
  /usr/lib/iserv/iserv-ipv6-import-wide-state --repair

Test "synchronize DHCPv6 state from ifupdown"
  /usr/lib/iserv/iserv-ipv6-sync-ifupdown-state
  ---
  /usr/lib/iserv/iserv-ipv6-sync-ifupdown-state --repair

EOF

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

cat <<'EOF'
Test "restart dhcpcd after importing WIDE DHCPv6 delegation state"
  { ! [ -s /var/lib/iserv/config/ipv6-dhcp-interfaces.list ] ||
    ! grep -Eq '^[[:space:]]*wide-dhcpv6-(sla-len|sla-id|ifid)[[:space:]]+' /etc/network/interfaces.d/ipv6; } ||
    grep -qx 20config-ipv6_restart-wide-dhcpcd /var/lib/iserv/config/update.log
  ---
  systemctl restart dhcpcd.service
  echo 20config-ipv6_restart-wide-dhcpcd >> /var/lib/iserv/config/update.log

EOF

echo
