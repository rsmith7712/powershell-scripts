<#
FILENAME:   azure_vm_provisioning.ps1

SUMMARY:    Create a fully configured virtual machine for Azure with PowerShell
PURPOSE:    Script creates an Azure virtual machine running Windows Server 2019.
            After runnning the script you can access the VM via RDP.
     
UPDATES:    Richard Smith, user10
SOURCE:     Microsoft
URL:        https://docs.microsoft.com/en-us/azure/virtual-machines/scripts/virtual-machines-windows-powershell-sample-create-vm

PRE-REQs:   1. Azure PowerShell Module
                * Install on Windows PowerShell 5.0 or newer
            2. Subscription in Azure you can connect to

ADD:        - Logging to Splunk

#>

###############################
#####     PRE-REQ CHKR    #####
#####       & UPDATER     #####
###############################

# Pre-Reqs - Check PowerShell Version (If PSVersion is 5.0 or newer, Continue Silently)
$PSVersionTable.PSVersion

# Pre-Req - Install Updates if needed to Windows PowerShell 5.1 (if already on Windows 10, you have PS5.1)
## (IDK best way to execute on this)

# Pre-Req - Install Update to .NET Framework 4.7.2 (or later)
# URL: https://docs.microsoft.com/en-us/dotnet/framework/install/on-windows-10


# Pre-Reqs - Install Azure PowerShell Module (Create Options List Requiring User Input)
# Install only for active user (If running for first time, Direct User to Select "A" for Yes to All)
Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Install for all users on a system (If running for first time, Direct User to Select "A" for Yes to All)
##Install-Module -Name Az -AllowClobber -Scope AllUsers

# Update Azure PowerShell Module (if needed)
Update-Module -Name Az -Force


###############################
#####     CONNECT TO      #####
#####       AZURE         #####
###############################

# Connect to specific Azure Tenant & Subscription Using Interactive Credentails (with 2 Factor Auth Enabled)
# Present list for User to Select Which Subscription They're Going To Be Provisionig To:

## Subscription - Domain Infrastructure
Connect-AzAccount -Tenant "f24185ae-9b1c-4daa-8e32-3bc7ba68b0c3" -SubscriptionId "01d5ab48-9005-4fa5-834b-a8adcbbc9895"
## Subscription  - Domain CI Dev
Connect-AzAccount -Tenant "f24185ae-9b1c-4daa-8e32-3bc7ba68b0c3" -SubscriptionId "ab4d3ed3-7821-4a7b-9841-c5009e270c53"
## Subscription  - Domain CI QA
Connect-AzAccount -Tenant "f24185ae-9b1c-4daa-8e32-3bc7ba68b0c3" -SubscriptionId "a8f3d063-1168-4593-906d-ab3812357582"
## Subscription  - Domain CI UAT
Connect-AzAccount -Tenant "f24185ae-9b1c-4daa-8e32-3bc7ba68b0c3" -SubscriptionId "1ed7d715-88b2-43f1-8669-4e127f0f5248"
## Subscription  - Domain Prod
Connect-AzAccount -Tenant "f24185ae-9b1c-4daa-8e32-3bc7ba68b0c3" -SubscriptionId "e4ed3a8d-ad61-4a09-aa90-7b611786b9e5"


###############################
#####     VM CREATION     #####
###############################

# Variables for common values
$resourceGroup = "sysadminResourceGroup"
$location = "westus2"
$vmName = "sysadminTestVM"

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a resource group
New-AzResourceGroup -Name $resourceGroup -Location $location

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 0.0.0.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name MYvNET -AddressPrefix 0.0.0.0/16 -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow

# Create a network security group
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name myNetworkSecurityGroup -SecurityRules $nsgRuleRDP

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_B2ms | `
Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2019-Datacenter -Version latest | `
Add-AzVMNetworkInterface -Id $nic.Id

# Create a virtual machine
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig


###############################
#####     CLEAN UP        #####
###############################

# Run the following command to remove the resource group, VM, and all related resources
##Remove-AzResourceGroup -Name myResourceGroup -WhatIf
