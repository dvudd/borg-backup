# borg-backup
My personal scripts to backup my systems
I'm using [Borg](https://borgbackup.readthedocs.io/en/stable/usage/general.html) to backup my files.

## Daily
`backup_daily.sh` runs every day at 02:00 to a internal drive on the server

## Weekly
`backup_weekly.sh` runs once a week and backups to a NAS. The NAS is turned off during the week, so the script first send a WOL packet and mounts the share after it's online.

## External *WORK IN PROGRESS*
`backup_external.sh` has to be run manually, I'm using a external HDD for this.

## Systemd
Systemd .service and .timer files should be placed at `/etc/systemd/system/`

`systemctl daemon-reload`
`systemctl enable backup_daily.timer`
`systemctl start backup_daily.timer`

## Log & XMPP notification
The scripts logs entries at `/var/log/backup-{daily/weekly}/$HOSTNAME_date.log`
If there's a warning or a error it also send a notification via xmpp
I have set $XMPP_TARGET as a global variable that points to my xmpp address.