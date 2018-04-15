#!/bin/bash

# requires azure-cli and jq installed
# requires Azure WebApp created 

# this script deploys a file, like a tomcat WAR file, to an Azure WebApp via ftp
# it pulls the Azure WebApp publishing profile to dynamically get the ftp server, userid and password
# you need to do 'az login' and set the wanted subscription before running this script

if [ $# -eq 0 ]; then
   echo "syntax: ftpwebappdeploy.sh resource-group-name webapp-name local-file"
fi

RGNAME=$1
WEBAPPNAME=$2
TARGETDIR="$(dirname "$3")"
TARGETFILE="$(basename "$3")"

echo "Getting publishing profile for $WEBAPPNAME..."
pubprofile=$(az webapp deployment list-publishing-profiles -g $RGNAME -n $WEBAPPNAME)

echo "Parsing publishing profile..."
publishUrl=$(echo $pubprofile | jq '.[1] | .publishUrl' | sed 's/"//')
FTPSERVER=$(echo $publishUrl | sed 's/ftp:\/\///' | cut -d '/' -f 1 | sed 's/"//')
idx=$(echo $FTPSERVER | awk '{print length}')
idx=$((idx+7)) # ftp://
ftpdir=$(echo $publishUrl | cut -c $idx-99 | sed 's/"//')
FTPUID=$(echo $pubprofile | jq '.[1] | .userName' | sed 's/"//' | sed 's/"//' | sed 's/\\\\/\\/')
FTPPWD=$(echo $pubprofile | jq '.[1] | .userPWD' | sed 's/"//' | sed 's/"//')

FTPDIR=$ftpdir/webapps

echo "ftp $TARGETDIR/$TARGETFILE --> $FTPSERVER $WEBAPPNAME $FTPDIR"

ftp -p -v -n $FTPSERVER << EOF

user "$FTPUID" "$FTPPWD"
cd $FTPDIR
lcd $TARGETDIR
binary
mput $TARGETFILE
quit

EOF

