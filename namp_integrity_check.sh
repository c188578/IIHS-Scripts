#!/bin/bash
############# Name : namp_integrity_check.sh ###############
#################### Version_number 0.01 ######################
# version 0.01 written by Sushant Goswami Dated 22-July-2021
# Revision
# Revision
# Revision
# Revision
######################## Scope ######################
# The script is intended to check the namp database integrity with active directory database
# scrip is needed to run via cron on specific interval
##################### User Defined Variables #########################
ZONE=ALL
PRIMARY_EMAIL=Tcs_Platform_Linux@lists.lilly.com
SECONDARY_EMAIL=ranjan_alok@network.lilly.com
PRIMARY_MAIL_ENABLE=1
SECONDARY_MAIL_ENABLE=1
WORKDIR=/var
LOGDIR=log
LOGFILE=namp_integrity_check_log.txt
TEMPDIR=tmp
############## Pre Fixed Variables ##############################
CURRENTDATE=`date | awk '{print $3"-"$2"-"$6}'`
CURRENTTIMESTAMP=`date | awk '{print $4}' | sed '$ s/:/./g'`
###################### Help Menu ##########################################
if [ -z $1 ]; then
 echo "(MSG 000): No arguments passed, continuing to regular task" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
else
 if [ $1 == "-help" ]; then
  echo "(MSG 001 HELP): The script is intended to check the namp database integrity with active directory database, it is needed to set it by cron"
  exit 0;
 fi
fi
#################### Do not edit below this line, use variables above ###########################################
###------------------------------------------------------------------------------------------------------------###
mail_send()
{
 if [ $SECONDARY_MAIL_ENABLE == 1 ]; then
  echo "$MAIL_MESSAGE" | mailx -s "Alert on $ZONE Master Sudo Server" $SECONDARY_EMAIL
 fi
 if [ $PRIMARY_MAIL_ENABLE == 1 ]; then
  echo "$MAIL_MESSAGE" | mailx -s "Alert on $ZONE Master Sudo Server" $PRIMARY_EMAIL
 fi
}
########################## Duplicate instance check ######################################
CHECK_ID=""
CHECK_ID=`ps -ef | grep "namp_integrity_check" | grep -v grep | grep -v tail | wc -l`
if [ $CHECK_ID -gt 4 ]; then
 echo "(MSG 002): Another intance of updsudo_shadow is running on background, please check and terminate the first session" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
 if [ $SECONDARY_MAIL_ENABLE == 1 ]; then
  echo "(MSG 002): Another intance of updsudo_shadow is running on background, please check and terminate the first session" | mailx -s "Alert on $ZONE Master Sudo Server" $SECONDARY_EMAIL
 fi
 if [ $PRIMARY_MAIL_ENABLE == 1 ]; then
  echo "(MSG 002): Another intance of updsudo_shadow is running on background, please check and terminate the first session" | mailx -s "Alert on $ZONE Master Sudo Server" $PRIMARY_EMAIL
 fi
 exit 0;
fi
########################## Duplicate instance check ######################################

########################## Main code #####################################
/remote/bin/namp/db/listuid > $WORKDIR/$TEMPDIR/tmp_nampuidlist01.txt
echo -e "$(sed '1d' $WORKDIR/$TEMPDIR/tmp_nampuidlist01.txt )\n" > $WORKDIR/$TEMPDIR/tmp_nampuidlist02.txt
tr '[A-Z]' '[a-z]' < $WORKDIR/$TEMPDIR/tmp_nampuidlist02.txt > $WORKDIR/$TEMPDIR/namp_integrity_check-nampuid-$CURRENTDATE.txt
rm -rf $WORKDIR/$TEMPDIR/tmp_nampuidlist01.txt $WORKDIR/$TEMPDIR/tmp_nampuidlist02.txt

adquery user | awk -F'[:=]' '{print $1 "\t" $3}' > $WORKDIR/$TEMPDIR/tmp_aduidlist01.txt
tr '[A-Z]' '[a-z]' < $WORKDIR/$TEMPDIR/tmp_aduidlist01.txt > $WORKDIR/$TEMPDIR/namp_integrity_check-aduid-$CURRENTDATE.txt
rm -rf $WORKDIR/$TEMPDIR/tmp_aduidlist01.txt

while read i;
 do
  a=`echo "$i" | awk '{print $1}'`
  b=`echo "$i" | awk '{print $2}'`
  c=`grep -i "$a " $WORKDIR/$TEMPDIR/namp_integrity_check-aduid-$CURRENTDATE.txt | wc -l`
   if [ $c -gt 1 ]; then
     echo "(MSG 003): more than two records found in AD for user $a in NAMP" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
   fi
   if [ $c == 1 ]; then
    d=`grep -i "$a " $WORKDIR/$TEMPDIR/namp_integrity_check-aduid-$CURRENTDATE.txt | awk '{print $1}'`
    e=`grep -i "$a " $WORKDIR/$TEMPDIR/namp_integrity_check-aduid-$CURRENTDATE.txt | awk '{print $2}'`
    if [ $b != $e ]; then
     echo "(MSG 003): Mismatch for user $a with uid $b in NAMP with id $e in AD" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
    fi
   fi
 done < $WORKDIR/$TEMPDIR/namp_integrity_check-nampuid-$CURRENTDATE.txt
 
 while read i;
 do
  a=`echo "$i" | awk '{print $1}'`
  b=`echo "$i" | awk '{print $2}'`
  c=`grep -i "$a " $WORKDIR/$TEMPDIR/namp_integrity_check-nampuid-$CURRENTDATE.txt | wc -l`
   if [ $c -gt 1 ]; then
     echo "(MSG 004): more than two records found in NAMP for user $a in AD" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
   fi
   if [ $c == 1 ]; then
    d=`grep -i "$a " $WORKDIR/$TEMPDIR/namp_integrity_check-nampuid-$CURRENTDATE.txt | awk '{print $1}'`
    e=`grep -i "$a " $WORKDIR/$TEMPDIR/namp_integrity_check-nampuid-$CURRENTDATE.txt | awk '{print $2}'`
    if [ $b != $e ]; then
     echo "(MSG 004): Mismatch for user $a with uid $b in AD with id $e in NAMP" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
    fi
   fi
 done < $WORKDIR/$TEMPDIR/namp_integrity_check-aduid-$CURRENTDATE.txt

########################## Main code #####################################
