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
SECONDARY_EMAIL=goswami_sushant@network.lilly.com
PRIMARY_MAIL_ENABLE=1
SECONDARY_MAIL_ENABLE=1
WORKDIR=/var
LOGDIR=log
LOGFILE=namp_integrity_check_log.txt
TEMPDIR=tmp
############## Pre Fixed Variables ##############################
CURRENTDATE=`date | awk '{print $3"-"$2"-"$6}'`
CURRENTTIMESTAMP=`date | awk '{print $4}' | sed '$ s/:/./g'`
SERVER_NAME=`hostname`
DOMAIN_NAME=am.lilly.com
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
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
 MAIL_MESSAGE="(MSG 002): Another instance of namp_integrity_check is running on background, please check and terminate the first session"
 mail_send
 exit 0;
fi
########################## Duplicate instance check ######################################

########################## Main code #####################################
/remote/bin/namp/db/listuid > $WORKDIR/$TEMPDIR/tmp_nampuidlist01.txt
echo -e "$(sed '1d' $WORKDIR/$TEMPDIR/tmp_nampuidlist01.txt )\n" > $WORKDIR/$TEMPDIR/tmp_nampuidlist02.txt
awk '{print "     " $0}' $WORKDIR/$TEMPDIR/tmp_nampuidlist02.txt > $WORKDIR/$TEMPDIR/tmp_nampuidlist03.txt
tr '[A-Z]' '[a-z]' < $WORKDIR/$TEMPDIR/tmp_nampuidlist03.txt > $WORKDIR/$TEMPDIR/namp_integrity_check-nampuid-$CURRENTDATE.txt

adquery user | awk -F'[:=]' '{print "  " $1 "\t" "  " $3}' > $WORKDIR/$TEMPDIR/tmp_aduidlist01.txt
tr '[A-Z]' '[a-z]' < $WORKDIR/$TEMPDIR/tmp_aduidlist01.txt > $WORKDIR/$TEMPDIR/namp_integrity_check-aduid-$CURRENTDATE.txt

/remote/bin/namp/db/listgid > $WORKDIR/$TEMPDIR/tmp_nampgidlist01.txt
echo -e "$(sed '1d' $WORKDIR/$TEMPDIR/tmp_nampgidlist01.txt )\n" > $WORKDIR/$TEMPDIR/tmp_nampgidlist02.txt
awk '{print "     " $0}' $WORKDIR/$TEMPDIR/tmp_nampgidlist02.txt > $WORKDIR/$TEMPDIR/tmp_nampgidlist03.txt
tr '[A-Z]' '[a-z]' < $WORKDIR/$TEMPDIR/tmp_nampgidlist03.txt > $WORKDIR/$TEMPDIR/namp_integrity_check-nampgid-$CURRENTDATE.txt

adquery group | awk -F'[:=]' '{print "  " $1 "\t" "  " $3}' > $WORKDIR/$TEMPDIR/tmp_adgidlist01.txt
tr '[A-Z]' '[a-z]' < $WORKDIR/$TEMPDIR/tmp_adgidlist01.txt > $WORKDIR/$TEMPDIR/namp_integrity_check-adgid-$CURRENTDATE.txt

########################## in Main code ## finding duplicates ##################################

while read i;
 do
  a=`echo "$i" | awk '{print $1}'`
  b=`echo "$i" | awk '{print $2}'`
  c=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-aduid-$CURRENTDATE.txt | wc -l`
   if [ $c -gt 1 ]; then
     echo "--------------------------------------------------------------------------" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     echo "(MSG 003): more than two records found in AD for user $a in NAMP DATABASE" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
   fi
   if [ $c == 1 ]; then
    d=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-aduid-$CURRENTDATE.txt | awk '{print $1}'`
    e=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-aduid-$CURRENTDATE.txt | awk '{print $2}'`
    if [ $b != $e ]; then
     echo "--------------------------------------------------------------------------" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     echo "(MSG 004): Mismatch for user $a with uid $b in NAMP with id $e in AD DATABASE" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
    fi
   fi
 done < $WORKDIR/$TEMPDIR/namp_integrity_check-nampuid-$CURRENTDATE.txt

 while read i;
 do
  a=`echo "$i" | awk '{print $1}'`
  b=`echo "$i" | awk '{print $2}'`
  c=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-nampuid-$CURRENTDATE.txt | wc -l`
   if [ $c -gt 1 ]; then
     echo "--------------------------------------------------------------------------" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     echo "(MSG 005): more than two records found in NAMP DB for user $a in respect with AD" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     cat $WORKDIR/$TEMPDIR/tmp_nampuidlist03.txt | grep -i " $a " | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4" In-the-NAMP "}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
   fi
   if [ $c == 1 ]; then
    d=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-nampuid-$CURRENTDATE.txt | awk '{print $1}'`
    e=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-nampuid-$CURRENTDATE.txt | awk '{print $2}'`
    if [ $b != $e ]; then
     echo "--------------------------------------------------------------------------" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     echo "(MSG 006): Mismatch for user $a with uid $b in AD with id $e in NAMP DATABASE" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     cat $WORKDIR/$TEMPDIR/tmp_nampuidlist03.txt | grep -i " $a " | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4" In-the-NAMP "}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     cat $WORKDIR/$TEMPDIR/tmp_aduidlist01.txt | grep -i " $a" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4" In-the-AD "}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
    fi
   fi
 done < $WORKDIR/$TEMPDIR/namp_integrity_check-aduid-$CURRENTDATE.txt

while read i;
 do
  a=`echo "$i" | awk '{print $1}'`
  b=`echo "$i" | awk '{print $2}'`
  c=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-adgid-$CURRENTDATE.txt | wc -l`
   if [ $c -gt 1 ]; then
     echo "--------------------------------------------------------------------------" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     echo "(MSG 007): more than two records found in AD for group $a in NAMP DATABASE" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
   fi
   if [ $c == 1 ]; then
    d=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-adgid-$CURRENTDATE.txt | awk '{print $1}'`
    e=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-adgid-$CURRENTDATE.txt | awk '{print $2}'`
    if [ $b != $e ]; then
     echo "--------------------------------------------------------------------------" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     echo "(MSG 008): Mismatch for group $a with gid $b in NAMP with id $e in AD DATABASE" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
    fi
   fi
 done < $WORKDIR/$TEMPDIR/namp_integrity_check-nampgid-$CURRENTDATE.txt

 while read i;
 do
  a=`echo "$i" | awk '{print $1}'`
  b=`echo "$i" | awk '{print $2}'`
  c=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-nampgid-$CURRENTDATE.txt | wc -l`
   if [ $c -gt 1 ]; then
     echo "--------------------------------------------------------------------------" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     echo "(MSG 009): more than two records found in NAMP for group $a in AD DATABASE" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     cat $WORKDIR/$TEMPDIR/tmp_nampgidlist03.txt | grep -i " $a " | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4" In the NAMP "}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
   fi
   if [ $c == 1 ]; then
    d=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-nampgid-$CURRENTDATE.txt | awk '{print $1}'`
    e=`grep -i " $a " $WORKDIR/$TEMPDIR/namp_integrity_check-nampgid-$CURRENTDATE.txt | awk '{print $2}'`
    if [ $b != $e ]; then
     echo "--------------------------------------------------------------------------" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     echo "(MSG 010): Mismatch for group $a with gid $b in AD with id $e in NAMP DATABASE" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     cat $WORKDIR/$TEMPDIR/tmp_nampgidlist03.txt | grep -i " $a " | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4" In-the-NAMP "}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
     cat $WORKDIR/$TEMPDIR/tmp_adgidlist01.txt | grep -i " $a" | sed -e "s/^/$(date | awk '{print $3"-"$2"-"$6"-"$4" In-the-AD "}') /" >> $WORKDIR/$LOGDIR/$LOGFILE
    fi
   fi
 done < $WORKDIR/$TEMPDIR/namp_integrity_check-adgid-$CURRENTDATE.txt

if [ $SECONDARY_MAIL_ENABLE == 1 ]; then
echo "NAMP integrity check script log file is attached on dated $CURRENTDATE" | mailx -s "NAMP integrity check script log file" -a $WORKDIR/$LOGDIR/$LOGFILE -r namp_integrity_checker@$SERVER_NAME.$DOMAIN_NAME $SECONDARY_EMAIL
fi
if [ $PRIMARY_MAIL_ENABLE == 1 ]; then
echo "NAMP integrity check script log file is attached on dated $CURRENTDATE" | mailx -s "NAMP integrity check script log file" -a $WORKDIR/$LOGDIR/$LOGFILE -r namp_integrity_checker@$SERVER_NAME.$DOMAIN_NAME $PRIMARY_EMAIL
fi

cp $WORKDIR/$LOGDIR/$LOGFILE $WORKDIR/$LOGDIR/$CURRENTTIMESTAMP-$LOGFILE
rm -rf $WORKDIR/$LOGDIR/$LOGFILE
rm -rf $WORKDIR/$TEMPDIR/tmp_nampuidlist01.txt $WORKDIR/$TEMPDIR/tmp_nampuidlist02.txt $WORKDIR/$TEMPDIR/tmp_nampuidlist03.txt
rm -rf $WORKDIR/$TEMPDIR/tmp_aduidlist01.txt
rm -rf $WORKDIR/$TEMPDIR/tmp_nampgidlist01.txt $WORKDIR/$TEMPDIR/tmp_nampgidlist02.txt $WORKDIR/$TEMPDIR/tmp_nampgidlist03.txt
rm -rf $WORKDIR/$TEMPDIR/tmp_adgidlist01.txt
########################## Main code ####################################
