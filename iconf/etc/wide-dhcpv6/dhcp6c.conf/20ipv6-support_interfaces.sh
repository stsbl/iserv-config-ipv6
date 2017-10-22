#!/bin/bash

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
  echo "        prefix ::/64 infinity;"
  echo
  id=0
  for i in $(netquery6 --format nic --lan | uniq | grep "$(cat /var/lib/iserv/config/ipv6-delegation-interfaces.list)")
  do
    echo "        prefix-interface $i {"
    let id++
    echo "                sla-id $id;"
    echo "                sla-len 0;"
    echo "        };"
    echo
  done
  echo "};"
  echo
fi
