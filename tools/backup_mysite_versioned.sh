#!/bin/bash


# Directories en bestanden voor backup
HOME="/home/pkn/MySite"
INCLUDE=(
	"db"
	"$HOME/public/images"
	"$HOME/config.yml"
	"$HOME/config_local.yml"
)

# Genereer een bestandsnaam met datum en tijd
TS=$(date +%Y%m%d_%H%M%S)
ARCHIVE="mysite_${TS}.tgz"

# Maak een tarball van de relevante content
tar czf "/tmp/$ARCHIVE" "${INCLUDE[@]}"

# Rsync naar Synology (let op: pad en module moeten kloppen)
sudo /usr/bin/rsync --no-group --password-file=/etc/rsync.secrets -az "/tmp/$ARCHIVE" rsync_user@syno.prjv.nl::backup/MySite/

# Verwijder de tijdelijke tgz
rm "/tmp/$ARCHIVE"
