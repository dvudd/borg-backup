#!/bin/sh
# SOURCE: https://github.com/borgbackup/borg/blob/master/docs/quickstart.rst
# Weekly backup to NAS

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Settings
export BORG_REPO=/mnt/backup
export BORG_PASSPHRASE=$(gpg --decrypt /etc/backups/borg.gpg)
export OPENSSL_CONF=/etc/backups/openssl_allow_tls1.0.cnf
archive_name=$(date +$HOSTNAME"_v"%U"_"%Y)
nas="nas.local"
nas_repo="/backup"
login=$(gpg --decrypt /etc/backups/credentials.gpg)

# Helpers and error handling:
# Note: $XMPP_TARGET is a global variable leading to my XMPP address
info() { logger -t "backup" "$*" >&2; }
xmpp() { echo "$*" | sendxmpp --tls-ca-path="/etc/ssl/certs" -t -n $XMPP_TARGET; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Weekly backup: Starting"

# Send magic packet to wake NAS then wait for it to become online
ether-wake -i eth0 A0:21:B7:C1:D1:8E

timeout 60 bash -c -- 'while ! ping -c 1 -n -w 1 $nas &> /dev/null; do sleep 1;done;'
nas_exit=$?
if [ $nas_exit -ne 0 ]; then
    info "Weekly backup: NAS did not come online!"
    xmpp "Weekly backup of $HOSTNAME finished with errors!!"
    exit 2
fi

# Mount NAS drive
sleep 5
mount -t nfs $nas:$nas_repo $BORG_REPO
sleep 5

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

borg create                                     \
    --verbose                                   \
    --filter archive_name                       \
    --list                                      \
    --stats                                     \
    --show-rc                                   \
    --compression lz4                           \
    --exclude-caches                            \
    --exclude-from '/etc/backups/exclude-list'  \
    ::$archive_name                             \
    /etc                                        \
    /home                                       \
    /root                                       \
    /var                                        \
    /usr/local/bin                              \
    /usr/local/sbin                             \
    /srv                                        \
    /opt >> /var/log/backup/$archive_name.log 2>&1

backup_exit=$?

info "Weekly backup: Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}_*' globbing is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune                          \
    --list                          \
    --glob-archives '{hostname}_*'  \
    --show-rc                       \
    --keep-weekly   4               \
    --keep-monthly  6 >> /var/log/backup/$archive_name.log 2>&1

prune_exit=$?

# Unmount NAS drive and tell it to shut off
umount $BORG_REPO
sleep 5

curl -u $login -k -d command=poweroff -d shutdown_option=1 -d OPERATION=set -d PAGE=System -d OUTER_TAB=tab_shutdown -d INNER_TAB=none https://$nas/get_handler &> /dev/null

# use highest exit code as exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 1 ];
then
    info "Weekly backup: Finished with warnings!"
    xmpp "Weekly backup of $HOSTNAME finished with warnings"
fi

if [ ${global_exit} -gt 1 ];
then
    info "Weekly backup: Finished with errors!!"
    xmpp "Weekly backup of $HOSTNAME finished with errors"
fi

exit ${global_exit}