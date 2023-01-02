#!/bin/bash

# Connect vuhb to ER Circuit

peering=$(az network express-route show -g ${RESOURCE_GROUP} --name ${ER_CIRCUIT_NAME} --query peerings[].id -o tsv)
routetableid=$(az network vhub route-table show --name defaultRouteTable --vhub-name ${VHUB_NAME} -g ${RESOURCE_GROUP} --query id -o tsv)

echo "Connecting ${VHUB_NAME} to ${ER_CIRCUIT_NAME} ..."

az network express-route gateway connection create \
--name conn-${ER_CIRCUIT_NAME} -g ${RESOURCE_GROUP} \
--gateway-name ${ER_GATEWAY_NAME} \
--peering $peering \
--associated-route-table $routetableid  \
--labels default &>/dev/null &
