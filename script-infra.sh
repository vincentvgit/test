#!/bin/bash
echo -----------------------Création du groupe de ressources-----------------------
echo Nom du Groupe de ressouces ? 
read RessGrp
echo Location ?                                        
read Location
echo --------------------Création du LoadBalancer-------------------
echo Nom du LoadBalancer ?
read LBname
echo -----------------Création de VM-------------------
echo Nom de la VM1 ?
read VM1
echo Image1 ?
read image1
echo Admin1 username ?
read adminVM1
echo Admin1 password ?
read pswd1
echo Nom de la VM2 ?
read VM2
echo Image2 ?
read image2
echo Admin2 username ?
read adminVM2
echo Admin2 password ?
read pswd2
echo ------------Création Base de données MariaDB------------------------- 
echo Name of your DB server ? 
read DBname 
echo Admin DB user name ? 
read DBuser
echo Mot de passe DATABASE ?
read pswDB 
echo -----------------------Création du groupe de ressources-----------------------
az group create \
    --name $RessGrp \
    --location $Location

echo ---------------------Création du Vnet----------------------------                               
az network vnet create \
    --resource-group $RessGrp \
    --location $Location \
    --name myVNet \
    --address-prefixes 10.1.0.0/16 \
    --subnet-name myBackendSubnet \
    --subnet-prefixes 10.1.0.0/24

echo --------------------Création IP PUBLIQUE-----------------------                        
az network public-ip create \
    --resource-group $RessGrp \
    --name myPublicIP \
    --sku Standard \
    --zone 1 2 3

echo --------------------Création du LoadBalancer-------------------
az network lb create \
    --resource-group $RessGrp \
    --name $LBname \
    --sku Standard \
    --public-ip-address myPublicIP \
    --frontend-ip-name myFrontEnd \
    --backend-pool-name myBackEndPool

echo --------------------Création HealthProbe------------------------
az network lb probe create \
    --resource-group $RessGrp \
    --lb-name $LBname \
    --name myHealthProbe \
    --protocol tcp \
    --port 80

echo --------------------LoadBalancer Rules------------------------
az network lb rule create \
    --resource-group $RessGrp \
    --lb-name $LBname \
    --name myHTTPRule \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name myFrontEnd \
    --backend-pool-name myBackEndPool \
    --probe-name myHealthProbe \
    --disable-outbound-snat true \
    --idle-timeout 15 \
    --enable-tcp-reset true

echo --------------------Création Security Network/Rules------------------------
az network nsg create \
    --resource-group $RessGrp \
    --name myNSG

az network nsg rule create \
    --resource-group $RessGrp \
    --nsg-name myNSG \
    --name myNSGRuleHTTP \
    --protocol '*' \
    --direction inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 80 \
    --access allow \
    --priority 200
echo --------------------Création IP Publique------------------------
az network public-ip create \
    --resource-group $RessGrp \
    --name myBastionIP \
    --sku Standard \
    --zone 1 2 3
echo --------------------Création sous-réseau BASTION------------------------
az network vnet subnet create \
    --resource-group $RessGrp \
    --name AzureBastionSubnet \
    --vnet-name myVNet \
    --address-prefixes 10.1.1.0/27

echo --------------------Création Hôte BASTION------------------------
az network bastion create \
    --resource-group $RessGrp \
    --name myBastionHost \
    --public-ip-address myBastionIP \
    --vnet-name myVNet \
    --location $Location

echo --------------------Création Interfaces Réseau------------------------
array=(myNicVM1 myNicVM2)
  for vmnic in "${array[@]}"
  do
    az network nic create \
        --resource-group $RessGrp \
        --name $vmnic \
        --vnet-name myVNet \
        --subnet myBackEndSubnet \
        --network-security-group myNSG
  done

echo -----------------Création de VM-------------------
az vm create \
    --resource-group $RessGrp \
    --name $VM1 \
    --nics myNicVM1 \
    --image $image1 \
    --admin-username $adminVM1 \
    --admin-password $pswd1 \
    --zone 1 \
    --no-wait

az vm create \
    --resource-group $RessGrp \
    --name $VM2 \
    --nics myNicVM2 \
    --image $image2 \
    --admin-username $adminVM2 \
    --admin-password $pswd2 \
    --zone 3 \
    --no-wait

echo --------------------Ajout des VM au pool de back-end du LoadBalancer------------------------
array=(myNicVM1 myNicVM2)
  for vmnic in "${array[@]}"
  do
    az network nic ip-config address-pool add \
     --address-pool myBackEndPool \
     --ip-config-name ipconfig1 \
     --nic-name $vmnic \
     --resource-group $RessGrp \
     --lb-name $LBname
  done

echo --------------------Création passerelle NAT------------------------
az network public-ip create \
    --resource-group $RessGrp \
    --name myNATgatewayIP \
    --sku Standard \
    --zone 1 2 3

echo --------------------Création ressource de passerelle NAT------------------------
az network nat gateway create \
    --resource-group $RessGrp \
    --name myNATgateway \
    --public-ip-addresses myNATgatewayIP \
    --idle-timeout 10

echo --------------------Associer une passerelle NAT à un Sous-réseau------------------------
az network vnet subnet update \
    --resource-group $RessGrp \
    --vnet-name myVNet \
    --name myBackendSubnet \
    --nat-gateway myNATgateway

echo ------------Création Base de données MariaDB------------------------- 
az mariadb server create \
    --name $DBname \
    -p $pswDB \
    --admin-user $DBuser \
    --location $Location \
    --resource-group $RessGrp \
    --backup-retention 10 \
    --geo-redundant-backup Enabled \
    --infrastructure-encryption Disabled \
    --ssl-enforcement Disabled \
    --storage-size 5120 \
    --tags "key=value" \
    --version 10.3 

echo --------------Création des règles du Pare-Feu-----------------------------
az mariadb server firewall-rule create \
    --resource-group $RessGrp \
    --server $DBname \
    --name AllowMyIP \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0 

az mariadb server update \
    --resource-group $RessGrp \
    --name $DBname \
    --ssl-enforcement Disabled 
