#!/bin/sh

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

BORG_REPO=/mnt/backup
nas="nas.local"
nas_repo="/backup"
login=$(gpg --decrypt /etc/backups/credentials.gpg)

ether-wake -i eth0 A0:21:B7:C1:D1:8E

timeout 60 bash -c -- "while ! ping -c 1 -n -w 1 $nas &> /dev/null; do sleep 1;done;"
nas_exit=$?
if [ $nas_exit -ne 0 ]; then
    echo "ERROR: NAS did not come online!"
    exit 2
fi

sleep 5
mount -t nfs $nas:$nas_repo $BORG_REPO
sleep 5

echo "NAS is online and mounted at $BORG_REPO"