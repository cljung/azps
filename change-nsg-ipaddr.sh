#!/bin/bash

rgname=""
nsgname=""
rulename="allow-all-from-temp-ip"

while test $# -gt 0
do
    case "$1" in
    -g|--resource-group) shift ; rgname=$1
            ;;
    -a|--nsg-name)       shift ; nsgname=$1
            ;;
    -n|--name)           shift ; rulename=$1
            ;;
    esac
    shift
done

if [ -z "$rgname" ]; then
  echo "resourceGroupName not specified"
  exit 1
fi

if [ -z "$nsgname" ]; then
  echo "NSG name not specified"
  exit 1
fi

if [ -z "$rulename" ]; then
  echo "NSG rule name not specified"
  exit 1
fi
  
resp=$(curl -X POST http://ipinfo.io)
ipaddr=$(echo $resp | jq '.ip' | sed "s/\"//g")
isporg=$(echo $resp | jq '.org' | sed "s/\"//g")
sourceAddrPrefix="$ipaddr/32"
description=$(echo "allow all inbound from temp ip $ipaddr, provider $isporg")

nsgrule=$(azure network nsg rule show -g $rgname --nsg-name $nsgname -n $rulename --json)

if [ ${#nsgrule} -gt 2 ]
then
  prio=$(echo $nsgrule | jq '.priority' | sed "s/\"//g")
  echo "Updating $rulename rule to allow $sourceAddrPrefix"
  azure network nsg rule set -g $rgname --nsg-name $nsgname -n $rulename \
                             --source-address-prefix $sourceAddrPrefix --source-port-range "*" \
                             --destination-address-prefix "*" --destination-port-range "*" \
                             --protocol "*" --direction "Inbound" --access "Allow" \
                             --priority $prio --description $description
else
  prio=1001
  echo "Adding $rulename rule to allow $sourceAddrPrefix with priority $prio"
  azure network nsg rule create -g $rgname --nsg-name $nsgname -n $rulename \
                             --source-address-prefix $sourceAddrPrefix --source-port-range "*" \
                             --destination-address-prefix "*" --destination-port-range "*" \
                             --protocol "*" --direction "Inbound" --access "Allow" \
                             --priority $prio --description $description
fi
