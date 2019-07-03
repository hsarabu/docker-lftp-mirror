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

echo "[$(date '+%H:%M:%S')] Starting up Synching"
echo "[$(date '+%H:%M:%S')] using lftp by Alexander V. Lukyanov (lftp.yar.ru)".

# create a directory for active downloads
mkdir -p /config/.download

# cycle every minute
while true
do
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
EOF
	 
	for file in /config/.download/*; do				
		lftp -u $USERNAME,$PASSWORD $HOST << EOF
			set sftp:auto-confirm yes
			command  rm "$REMOTE_DIR/${file##*/}"
EOF
		echo "[$(date '+%H:%M:%S')] Setting permission..."
		chmod -R 777 /config/.download
		mv /config/.download/* $FINISHED_DIR	
		echo "[$(date '+%H:%M:%S')] Finished moving files..."	
	done
	
# Repeat process after one minute
echo "[$(date '+%H:%M:%S')] Sleeping for 1 minute"
sleep 1m

done
