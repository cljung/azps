# Sundry Azure Powershell and Bash scripts

- change-lgw-ipaddr.ps1/.sh - Updates a Local Network Gateway to the current ip address from a nslookup. Good if the VPN router on-premises is behind a dynamic ip address that changes over time
- change-nsg-ipaddr.ps1/.sh - Updates a Network Security Group to allow all traffic from the ip address you are currently working from. Good for roaming development
- list-vpngw-tree.ps1 - Traverses all subscriptions and builds a VNet tree. Good when you have alot of VNet peerings and want an overview how all VNets hang together with ip address ranges and all
- save-vm-existing.ps1 / create-vm-existing.ps1 - Scripts that will save the config of a VM so you can delete it and then recreate it from the saved disks. Good when you neet to rebuild your VNet or move you VMs to another region
- ftpwebappdeploy.sh - Bash script that deploys a tomcat WAR-file (or any file) to an Azure WebApp via ftp by dynamically downloading the publishing profile for the WebApp from Azure to get ftp information
- web-deploy-website-tomcat.ps1 - Script that deploys an Azure WebApp by msdeploy. You can deploy anything, like php or old ASP apps, to Azure using this script
- perfmon-onstart.ps1 - Script that creates a Scheduled Task that runs perfmon for a while after each reboot on a VM
