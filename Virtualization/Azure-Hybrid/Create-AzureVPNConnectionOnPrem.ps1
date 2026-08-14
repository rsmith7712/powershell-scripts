# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    Create-AzureVPNConnectionOnPrem.ps1

    .SYNOPSIS
    Deploys Azure resources and configures VPN to connect back to on-prem SSC VPN.
    
    .DESCRIPTION
   This script will deploy the following resources in Azure, resource Group, Virtual Network, GateWay subnet, Public IP Address, Local Network Gateway, 
   Virtual Network Gateway in Availability Zone, Configure BGP Connection and apply Tags.
    
    .NOTES
    Version:        2.0
    Author:         HOh@example.com
    Creation Date:  07/19/19

.FUNCTIONALITY
    This script will deploy the following resources in Azure, resource Group, Virtual Network, GateWay subnet, Public IP Address, Local Network Gateway,
       Virtual Network Gateway in Availability Zone, Configure BGP Connection and apply Tags.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Connect to Azure using PowerShell
#Authenticate to Azure with your credentials(Browse to https://microsoft.com/devicelogin and enter code to authenticate)
Login-AzAccount

#Shows current subscritpion and verify it's Domain Infratstruture Subscription
Get-azcontext

#If not pointing to Domain Infra subcription then run the following command
#set-azcontext -SubscriptionId "01d5ab48-9005-4fa5-834b-a8adcbbc9895"

#Variables for on-prem to Azure VPN resources
#ResourceGroup Name
$ResourceGroup = 'infra-networking3'
#Resource Location
$location = 'WestUs2'
#VNet Name
$VnetName = 'infra-wan-vnet3'
#VNET IP Addressing (Provided by Networking Team)
$AddressSpace = '0.0.0.0/24'
#On-prem Intenral DNS Server IP Address
$DnsServer = '0.0.0.0'
#Gateway Subnet Name (Gateway subnet must be named GatewaySubnet)
$GatewayName = 'GatewaySubnet'
#Create new Gateway Subnet and set IP Addressing
$subnetGW = New-AzVirtualNetworkSubnetConfig -Name $GatewayName -AddressPrefix $AddressSpace
#Local Network Gateway Name
$lng = 'infra-vpn-lgn3'
#Virtual Network Gateway Name
$VPNGateway = 'infra-vpn-gw3'
#PUbic IP Address Name
$gwpubipName = 'infra-vpn-ip3' 


#Create Resource Group and set location
New-AzResourceGroup -Name $ResourceGroup -Location $location

#Create Virtual Network and create Gateway subnet
New-AzVirtualNetwork -Name $VnetName -ResourceGroupName $ResourceGroup `
-Location $location  -AddressPrefix $AddressSpace -Subnet $subnetGW -DnsServer $DnsServer

#Request Public IP Address
$pip1 = New-AzPublicIpAddress -ResourceGroup $ResourceGroup -Location $Location -Name $gwpubipname -AllocationMethod Static -Sku Standard

#Create IP Configuration
$getvnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $VNetName
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $GatewayName -VirtualNetwork $getvnet
$gwipconf1 = New-AzVirtualNetworkGatewayIpConfig -Name $gwpubipName -Subnet $subnet -PublicIpAddress $pip1

#Create New Availability Zone virtual Network Gateway VPN
New-AzVirtualNetworkGateway -Name $VPNGateway -ResourceGroupName $ResourceGroup `
-Location $location -IpConfigurations $GwIPConf1 -GatewayType Vpn `
-VpnType RouteBased -GatewaySku VpnGw1AZ

#Create Local Network Gateway for VPN using BGP
#On-prem Internal Network IP Address
$IntIP = '0.0.0.0/16'
#On-prem VPN Appliance IP Address (Provided by Networking Team)
$GWextip = '0.0.0.0'
#on-prem VPN BGP IP Address (Provided by Networking Team)
$BGPip = '0.0.0.0'
#on-prem VPN BGP ASN (Provided by Networking Team)
$BGPAsn = '65001'

New-AzLocalNetworkGateway -Name $lng -ResourceGroupName $ResourceGroup -Location $location -AddressPrefix $Intip -GatewayIpAddress $Gwextip -Asn $BGPASn -BgpPeeringAddress $BGPip

#Create New custom IPSEC Policy (Provided by Networking Team)
#IKEv2: AES256, SHA256, DHGroup14 (Modify as needed) 
#IPsec: AES256,SHA256, PFS 14, SA Lifetime 27000 @ 102400000KB
$ipsecpolicy6 = New-AzIpsecPolicy `
-IkeEncryption AES256 `
-IkeIntegrity SHA256 `
-DhGroup DHGroup14 `
-IpsecEncryption AES256 `
-IpsecIntegrity SHA256 `
-PfsGroup PFS2048 `
-SALifeTimeSeconds 27000 `
-SADataSizeKilobytes 102400000

#Get Vritual Network Gateway
$vnet1gw = Get-AzVirtualNetworkGateway `
-Name $VPNGateway `
-ResourceGroupName $ResourceGroup
#Get Local Network Gateway
$lng2 = Get-AzLocalNetworkGateway `
-Name $lng `
-ResourceGroupName $ResourceGroup
#on-prem VPN SharedKey (Provided by Networking Team)
$SharedKey = '71acc9ed27c58662167c0f1350928e611bcb5cd8eed0f9d8e2eda9750e380067'

#Set Virtual Network Gateway Connection Name
$vngc = "infra-vpn-lng-con2"

#Create new Virtual Network Gateway Connection (Azure-JuniperSRX VPN)
New-AzVirtualNetworkGatewayConnection -Name $vngc -ResourceGroupName $ResourceGroup -VirtualNetworkGateway1 $vnet1gw -LocalNetworkGateway2 $lng2 -Location $location -EnableBgp:$true -ConnectionType IPsec -IpsecPolicies $ipsecpolicy6 -SharedKey $SharedKey

#Apply Tags to the Resource Group
Get-AzResourceGroup $Resourcegroup | Set-AzResourceGroup -Tag @{ManagedBy="Networking Group";BusinessOwner="I.T."}

#Retrieve resources from Resource Group
$ResourceTag = Get-AzResource -ResourceGroupName $ResourceGroup
#Apply Tags to all resources in Resource Group
$ResourceTag | Set-AzResource -Tag @{ManagedBy="Networking Group";BusinessOwner="I.T."} -Force

#Verify VPN Connection
Get-AzVirtualNetworkGatewayConnection -ResourceGroupName $ResourceGroup
