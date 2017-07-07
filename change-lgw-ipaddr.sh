#!/bin/bash

rgname=""
lgwname=""
endpointname=""

while test $# -gt 0
do
    case "$1" in
    -g|--resource-group) shift ; rgname=$1
            ;;
    -n|--lgw-name)       shift ; lgwname=$1
            ;;
    -l|--localendpoint)           shift ; endpointname=$1
            ;;
    esac
    shift
done

if [ -z "$rgname" ]; then
  echo "resourceGroupName not specified"
  exit 1
fi

if [ -z "$lgwname" ]; then
  echo "Local Gateway name not specified"
  exit 1
fi

if [ -z "$endpointname" ]; then
  echo "Endpoint name not specified"
  exit 1
fi
  
ipaddr=$(nslookup $endpointname | awk '/^Address: / { print $2 }')  

lgwrule=$(azure network local-gateway show -g $rgname -n $lgwname --json)

if [ ${#lgwrule} -gt 2 ]
then
  gwipaddr=$(echo $lgwrule | jq '.gatewayIpAddress' | sed "s/\"//g")
  echo "$endpointname is currently $gwipaddr"
  if [ "$ipaddr" != "$gwipaddr" ] 
  then
    echo "Updating to $ipaddr..."
    azure network local-gateway set -g $rgname -n $lgwname -i $ipaddr 
  else
    echo "nslookup gives same ip - doing nothing"
  fi
else
  echo "Azure Local Gateway $lgwname not found"
fi
