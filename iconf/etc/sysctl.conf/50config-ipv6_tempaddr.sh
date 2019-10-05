#!/bin/bash

if [ ! -f "/var/lib/dpkg/info/iserv-backup.list" ] &&
    [ ! -f "/var/lib/dpkg/info/iserv-backup2-server.list" ] &&
    [ -n "$(netquery6 -wg nic)" ]
then
  echo "# Prefer tempaddr for wan interfaces"
  for nic in $(netquery6 -wg nic)
  do
    echo "net.ipv6.conf.$nic.use_tempaddr = 2"
  done
fi

[ -n "$(netquery6 -gl nic)" ] && echo "# Kill tempaddr for lan interfaces"

for nic in $(netquery6 -gl nic)
do
  echo "net.ipv6.conf.$nic.use_tempaddr = 0"
done

if [ -n "$(netquery6 -wg nic)" ] &&
    ([ -f "/var/lib/dpkg/info/iserv-backup.list" ]] ||
    [ -f "/var/lib/dpkg/info/iserv-backup2-server.list" ])
then
  echo "# Kill tempaddr as backupmon has problems with it"
  for nic in $(netquery6 -wg nic)
  do
    echo "net.ipv6.conf.$nic.use_tempaddr = 0"
  done
fi
echo
