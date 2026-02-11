#!/bin/bash

# Pad naar de originele database
SRC="/home/pkn/MySite/db/mysite.sqlite"

# Genereer een bestandsnaam met datum en tijd
TS=$(date +%Y%m%d_%H%M%S)
BASENAME="mysite_${TS}.sqlite"

# Maak een tijdelijke kopie met timestamp
cp "$SRC" "/tmp/$BASENAME"

# Rsync naar Synology (let op: pad en module moeten kloppen)
sudo /usr/bin/rsync --no-group --password-file=/etc/rsync.secrets -az "/tmp/$BASENAME" rsync_user@syno.prjv.nl::backup/MySite/

# Verwijder de tijdelijke kopie
rm "/tmp/$BASENAME"
