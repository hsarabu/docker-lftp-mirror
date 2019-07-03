#!/bin/sh

# Display variables for troubleshooting
echo -e "Variables set:\\n\

PUID=${PUID}\\n\
PGID=${PGID}\\n\

HOST=${HOST}\\n\
USERNAME=${USERNAME}\\n\
PASSWORD=${PASSWORD}\\n\

REMOTE_DIR=${REMOTE_DIR}\\n\
FINISHED_DIR=${FINISHED_DIR}\\n\
LFTP_PARTS=${LFTP_PARTS}\\n\
LFTP_FILES=${LFTP_FILES}\\n"

BASE_NAME="$(basename "$0")"
LOCK_FILE="/tmp/$BASE_NAME.lock"

echo "[$(date '+%H:%M:%S')] Starting up Synching"
echo "[$(date '+%H:%M:%S')] using lftp by Alexander V. Lukyanov (lftp.yar.ru)".

# if no finished files directory specified, default to /config/download
[ -z "$FINISHED_DIR" ] && FINISHED_DIR="/config/download"

# create a directory for placing private key for lftp to use
mkdir -p /config/ssh

# create a directory for active downloads
mkdir -p /config/.download

# create finished downloads directory
mkdir -p /config/download

# Cycle every minute
while true
do

trap "rm -f $LOCK_FILE" SIGINT SIGTERM
if [[ -e "$LOCK_FILE" ]]
then
    echo "[$(date '+%H:%M:%S')] $BASE_NAME is running already."
else
    touch "$LOCK_FILE"
	echo "[$(date '+%H:%M:%S')] Created lock file."
	
	echo "[$(date '+%H:%M:%S')] Initiating connection to $host using sftp"	
	
    lftp -u $USERNAME,$PASSWORD $HOST << EOF
    set sftp:auto-confirm yes
    set mirror:use-pget-n $LFTP_PARTS
	set net:connection-limit 50
	set xfer:log 1
	set xfer:eta-period 5 
	set xfer:use-temp-file yes
	set pget:save-status never
	mirror -v -P$LFTP_FILES --log="/config/$BASE_NAME.log" $REMOTE_DIR /config/.download
    quit
EOF
 
for file in /config/.download/*; do	
		
	if [ "$REMOTE_DIR/*" = "${REMOTE_DIR}/${file##*/}" ]; then
		echo "[$(date '+%H:%M:%S')] No files were synchronized."
		rm -f "$LOCK_FILE"
		trap - SIGINT SIGTERM	
	else	
		echo "[$(date '+%H:%M:%S')] Transfers are completed... !"
		lftp -u $USERNAME,$PASSWORD $HOST << EOF
		set sftp:auto-confirm yes
		command  rm "${remote_dir}/${file##*/}" 
    quit	
EOF
fi
	echo "[$(date '+%H:%M:%S')] Moving files off Sync to Download folder."
	chmod -R 777 /config/.download/*
	mv "${/config/.download}/${file##*/}" "$FINISHED_DIR"		
    rm -f "$LOCK_FILE"
    trap - SIGINT SIGTERM		
fi
    # Repeat process after one minute
    echo "[$(date '+%H:%M:%S')] Sleeping for 1 minute"
    sleep 1m
done
