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

#lgwrule=$(az network local-gateway show -g $rgname -n $lgwname --json)
gwipaddr=$(az network local-gateway show -g $rgname -n $lgwname --query "gatewayIpAddress" | sed "s/\"//g")

if [ ${#gwipaddr} -gt 2 ]
then
  echo "$endpointname is currently $gwipaddr"
  if [ "$ipaddr" != "$gwipaddr" ] 
  then
    echo "Updating to $ipaddr..."
    az network local-gateway update -g $rgname -n $lgwname --gateway-ip-address $ipaddr 
  else
    echo "nslookup gives same ip - doing nothing"
  fi
else
  echo "Azure Local Gateway $lgwname not found"
fi
