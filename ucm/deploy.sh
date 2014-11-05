#!/bin/bash
# 
# License: This code is licensed as per the LICENSE file
# included.
#
# Script to deploy CMU bundles. Currently this ONLY uploads them to the content
# server - it does not yet import them.
# Update: this now imports them as well
#
# Todo:
# * Import the cmu bundles that were uploaded
#
# Author: Kris Foster kristian.foster@gmail.com
#

USAGE="USAGE: deploy_cmu FILE UCM_SERVER[e.g. http://localhost/idc] USER PASSWORD [import] [debug]"
OUT_FILE=/dev/null

# Check the required params
if [ "$#" -lt "4" ]
then
	echo $USAGE
	exit 1
fi
if [ "$1" = "" ]
then
	echo "No file specified."
	echo $USAGE
	exit 1
fi
FILE=$1
if [ "$2" = "" ]
then
	echo "No UCM server defined. Ensure SVR vaiable is being set."
	echo $USAGE
	exit 1
fi
SVR=$2
if [ "$3" = "" ]
then
	echo "No UCM logon defined. Ensure USR vaiable is being set."
	echo $USAGE
	exit 1
fi
USR=$3
if [ "$4" = "" ]
then
	echo "No UCM password defined. Ensure you pass a sysadmin password in from the command line"
	echo $USAGE
	exit 1
fi
PASS=$4
if [ "$5" = "import" ]
then
	IMPORT="true"
else [ "$5" = "debug" ]
	OUT_FILE=./cmu.log
	echo "Log of cmu sent to $OUT_FILE"
fi
if [ "$6" = "debug" ]
then
	OUT_FILE=./cmu.log
	echo "Log of cmu sent to $OUT_FILE"
fi

# Loop through all the CMU bundles in the folder and upload them to the Content Server
echo "Uploading $FILE...."
echo "Connecting to $SVR as User=$USR with password=$PASS"
curl -u $USR:$PASS -F "IdcService=CMU_UPLOAD_BUNDLE" -F "bundleName=@$FILE" -F "createExportTemplate=" -F "forceBundleOverwrite=yes" $SVR/idcplg >> $OUT_FILE 
echo "File uploaded..."

# The following extracts the taskname for the CMU import bundle from the zipped bundle - it is stored in the task.hda file
export TASKNAME=`unzip -p $FILE task.hda | grep -A 0 '^TaskName=' | awk -F"=" '{print $2}'`

# Record the current time - we will use this to identify the current import when checking to see if it has finished
export NOW=`date "+%d/%m/%Y %H:%M"`

if [ "$IMPORT" = "true" ]
then
	echo "Importing the CMU bundle: $FILE TaskName: $TASKNAME..."
	curl -u $USR:$PASS -F "isContinueOnError=1" -F "isOverwrite=1" -F "IdcService=CMU_UPDATE_AND_CREATE_ACTION" -F "sectionItemList=" -F "TaskName=$TASKNAME" -F "isImport=1" $SVR/idcplg >> $OUT_FILE
	echo "Upload of $TASKNAME is complete..."
fi

lynx -auth=$USR:$PASS $SVR/idcplg?IdcService=CMU_GET_ALL_IMPORT_BUNDLES
