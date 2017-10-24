#!/bin/bash

prefix_len=62

if [ -r "/etc/iserv/dhcpv6-prefix" ]
then
  prefix_len=$(cat /etc/iserv/dhcpv6-prefix)
fi

dhcp_interfaces=0
for i in $(netquery6 --format nic | uniq | grep "$(cat /var/lib/iserv/config/ipv6-dhcp-interfaces.list)")
do
  echo "interface $i {"
  echo "        send ia-pd 0;"
  echo "        send rapid-commit;"
  echo "};"
  echo
  let dhcp_interfaces++
done

if [ $dhcp_interfaces -gt 0 ] && [[ $(netquery6 --format nic --lan | uniq | grep "$(cat /var/lib/iserv/config/ipv6-delegation-interfaces.list)" | wc -l) -gt 0 ]]
then
  echo "id-assoc pd 0 {"
  echo "        prefix ::/$prefix_len infinity;"
  echo
  id=0
  for i in $(netquery6 --format nic --lan | uniq | grep "$(cat /var/lib/iserv/config/ipv6-delegation-interfaces.list)")
  do
    echo "        prefix-interface $i {"
    let id++
    echo "                sla-id $id;"
    echo "                sla-len $(expr 128 - 64 - $prefix_len);"
    echo "        };"
    echo
  done
  echo "};"
  echo
fi
