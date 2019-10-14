#!/bin/bash

WanNics=($(netquery6 -wg nic | sort | uniq | sed 's#\.#/#g'))
LanNics=($(netquery6 -gul nic | sort | uniq | sed 's#\.#/#g'))

if [ ! -f "/var/lib/dpkg/info/iserv-backup.list" ] &&
    [ ! -f "/var/lib/dpkg/info/iserv-backup2-server.list" ] &&
    [[ ${#WanNics[@]} -gt 0 ]]
then
  echo "# Prefer tempaddr for wan interfaces"
  for nic in ${WanNics[@]}
  do
    echo "net.ipv6.conf.$nic.use_tempaddr = 2"
  done
fi

if [[ ${#LanNics[@]} -gt 0 ]]
then
  echo "# Kill tempaddr for lan interfaces"

  for nic in ${LanNics[@]}
  do
    echo "net.ipv6.conf.$nic.use_tempaddr = 0"
  done
fi

if [[ ${#WanNics[@]} -gt 0 ]] &&
    ([ -f "/var/lib/dpkg/info/iserv-backup.list" ] ||
    [ -f "/var/lib/dpkg/info/iserv-backup2-server.list" ])
then
  echo "# Kill tempaddr as backupmon has problems with it"
  for nic in ${WanNics[@]}
  do
    echo "net.ipv6.conf.$nic.use_tempaddr = 0"
  done
fi
echo
