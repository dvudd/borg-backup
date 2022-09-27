#!/bin/sh

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

export OPENSSL_CONF=/etc/backups/openssl_allow_tls1.0.cnf
BORG_REPO=/mnt/backup
nas="nas.local"
login=$(gpg --decrypt /etc/backups/credentials.gpg)

umount $BORG_REPO
sleep 5
curl -u $login -k -d command=poweroff -d shutdown_option=1 -d OPERATION=set -d PAGE=System -d OUTER_TAB=tab_shutdown -d INNER_TAB=none https://$nas/get_handler &> /dev/null
echo "NAS is shutting down"