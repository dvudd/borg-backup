#!/bin/sh
# Backup to external media

export BORG_REPO=/mnt/backup
export BORG_PASSPHRASE=$(gpg --decrypt /etc/backups/borg.gpg)

mount -t xfs /dev/XXX /mnt/external
mount_hdd=$?
if [ $mount_hdd -ne 0 ]; then
    info "External backup: Could not mount external drive"
    xmpp "External backup of $HOSTNAME finished with errors!!"
    exit 2
fi
touch /mnt/external/tempfile
write_test=$?
if [ $write_test -ne 0 ]; then
    info "External backup: Could not write to external drive"
    xmpp "External backup of $HOSTNAME finished with errors!!"
    exit 2
fi
rm /mnt/external/tempfile

archive_name=$(borg list --last 1 | awk '{ print $1 }')

borg export-tar $BORG_REPO::$archive_name /mnt/external/$archive_name.tar.gz >> /var/log/backup-external/$archive_name.log 2>&1
backup_exit=$?
if [ $backup_exit -ne 0 ]; then
    info "External backup: Finished with errors!!"
    xmpp "External backup of $HOSTNAME finished with errors!!"
    exit 2
fi

exit${backup_exit}