#!/bin/bash

rgname=""
nsgname=""
rulename="allow-all-from-temp-ip"

while test $# -gt 0
do
    case "$1" in
    -g|--resource-group) shift ; rgname=$1
            ;;
    -n|--nsg-name)       shift ; nsgname=$1
            ;;
    -r|--rule)           shift ; rulename=$1
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
  
resp=$(curl -X GET http://ipinfo.io/)
ipaddr=$(echo $resp | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\042'ip'\042/){print $(i+1)}}}' | tr -d '"' | sed -e 's/^[[:space:]]*//')
isporg=$(echo $resp | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\042'org'\042/){print $(i+1)}}}' | tr -d '"' | sed -e 's/^[[:space:]]*//')

sourceAddrPrefix="$ipaddr/32"
description=$(echo "allow all inbound from temp ip $ipaddr, provider $isporg")

nsgrule=$(az network nsg rule show -g $rgname --nsg-name $nsgname -n $rulename -o tsv --query "sourceAddressPrefix")


if [ ${#nsgrule} -gt 2 ]
then
  prio=$(az network nsg rule show -g $rgname --nsg-name $nsgname -n $rulename -o tsv --query "priority")
  echo "Updating $rulename rule to allow $sourceAddrPrefix"
  az network nsg rule update -g $rgname --nsg-name $nsgname -n $rulename \
                             --source-address-prefixes $sourceAddrPrefix --source-port-ranges "*" \
                             --destination-address-prefixes "*" --destination-port-ranges "*" \
                             --protocol "*" --direction "Inbound" --access "Allow" \
                             --priority $prio --description "$description"
else
  prio=1001
  echo "Adding $rulename rule to allow $sourceAddrPrefix with priority $prio"
  az network nsg rule create -g $rgname --nsg-name $nsgname -n $rulename \
                             --source-address-prefixes $sourceAddrPrefix --source-port-ranges "*" \
                             --destination-address-prefixes "*" --destination-port-ranges "*" \
                             --protocol "*" --direction "Inbound" --access "Allow" \
                             --priority $prio --description "$description"
fi
