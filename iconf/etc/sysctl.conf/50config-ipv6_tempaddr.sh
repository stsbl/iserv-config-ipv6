#!/bin/bash

WanNics=($(netquery6 -wg nic | sort | uniq | sed 's#\.#/#g'))
LanNics=($(netquery6 -gul nic | sort | uniq | sed 's#\.#/#g'))

if [[ ${#LanNics[@]} -gt 0 ]]
then
  echo "# Kill tempaddr for LAN interfaces"

  for nic in ${LanNics[@]}
  do
    echo "net.ipv6.conf.$nic.use_tempaddr = 0"
  done
fi

if [[ ${#WanNics[@]} -gt 0 ]]
then
  echo "# Kill tempaddr for WAN interfaces"
  for nic in ${WanNics[@]}
  do
    echo "net.ipv6.conf.$nic.use_tempaddr = 0"
  done
fi
echo
