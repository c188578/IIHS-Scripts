#!/bin/bash
############# Name : updsudo_shadow ###############
#################### Version ######################
# version 0.01 written by Sushant Goswami Dated 17-Aug-2017
# Revision 0.02 written by Alok Ranjan Dated 24-Oct-2017
# Revision
# Revision
# Revision
######################## Scope ######################
# The script is intended to check the master sudoers file on regular interval.
# ideally it can be set through the crontab
# 1. If the main file and the file before UPDSUDO_HOUR_CHECK hours are having difference by more than SIZE_LIMIT Bytes than it will trigger email.
# 2. If there is a "vi" session opened for more than UPDSUDO_HOUR_CHECK hour than it will trigger email.
# 3. If the file is modified then the modification will be sent to PRIMARY_EMAIL
# the modification email will be sent only to PRIMARY_EMAIL
# 4. the script will maintain a log file which is set by LOGDIR and LOGFILE variable
# 5. Script will keep modified sudo file backup for 3 days
# 6. Script also keep backup of sudo file every 2 hour and for 3 days
##################### User Defined Variables #########################
ZONE=ALL
PRIMARY_EMAIL=Tcs_Platform_Linux@lists.lilly.com
SECONDARY_EMAIL=ranjan_alok@network.lilly.com
PRIMARY_MAIL_ENABLE=1
SECONDARY_MAIL_ENABLE=1
SIZE_LIMIT=512
WORKDIR=/etc/msudoers/updsudo_shadow
UPDSUDO_WORKDIR=/etc/msudoers
AUTO_BACKUP_DIR=backup
SUDO_FILE=master.sudoers
LOGDIR=log
LOGFILE=updsudo_shadow.log
TEMPDIR=tmp
CHANGE_DIR=changes
UPDSUDO_HOUR_CHECK=01
############## Pre Fixed Variables ##############################
CURRENTDATE=`date | awk '{print $3"-"$2"-"$6}'`
CURRENTTIMESTAMP=`date | awk '{print $4}' | sed '$ s/:/./g'`
LAST_FILE_DATE=""
LAST_FILE_HOUR=""
LAST_FILE_DATE=`ls -ltr $WORKDIR/$AUTO_BACKUP_DIR | tail -1 | awk '{print $9}' | cut -d "-" -f 2,3,4`
LAST_FILE_HOUR=`ls -ltr $WORKDIR/$AUTO_BACKUP_DIR | tail -1 | awk '{print $9}' | cut -d "-" -f 5 | cut -d "." -f 1`
CURRENT_HOUR=`date | awk '{print $4}' | cut -d ":" -f 1`
COPY_FLAG=0
###################### Help Menu ##########################################
if [ -z $1 ]; then
 echo "(MSG 000): No arguments passed, continuing to regular task" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
else
 if [ $1 == "-help" ]; then
  echo "(MSG HELP): The script is intended to check the master sudoers file on regular interval, it is needed to set it by cron"
  exit 0;
 fi
fi
#################### Do not edit below this line, use variables above ###########################################
###------------------------------------------------------------------------------------------------------------###
########################## Duplicate instance check ######################################
CHECK_ID=""
CHECK_ID=`ps -ef | grep "updsudo_shadow" | grep -v grep | grep -v tail | wc -l`
if [ $CHECK_ID -gt 4 ]; then
 echo "(MSG 001): Another intance of updsudo_shadow is running on background, please check and terminate the first session" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
 if [ $SECONDARY_MAIL_ENABLE == 1 ]; then
  echo "(MSG 001): Another intance of updsudo_shadow is running on background, please check and terminate the first session" | mailx -s "Alert on $ZONE Master Sudo Server" $SECONDARY_EMAIL
 fi
 exit 0;
fi
CHECK_VI=""
CHECK_VI=`ps -ef | grep "vi updsudo_shadow" | grep -v grep | wc -l`
if [ $CHECK_VI != 0 ]; then
 echo "(MSG 002): vi sessions are running on the background for updsudo_shadow, please close the existing sessions" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
 if [ $SECONDARY_MAIL_ENABLE == 1 ]; then
  echo "(MSG 002): vi sessions are running on the background for updsudo_shadow, please close the existing sessions" | mailx -s "Alert on $ZONE Master Sudo Server" $SECONDARY_EMAIL
 fi
 exit 0;
fi
