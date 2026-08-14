# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Richard Smith

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
    [WORKING]SysOps-New-OrionStore-ServerSetup_v2.ps1

.IMPORTANT
    This script must be executed from within the CDE & Directly on one of the Orion server/s themselves
        - Orion Server1:0.0.0.0  <-- Primary
        - Orion Server2:0.0.0.0  <-- Secondary

        - For this store server script, $ConnectionType has been commented out
            * DO NOT ENABLE THIS * as it will break NetAdmins alerting features


.SYNOPSIS
  Script to add Retail Server elements (iDrac + ESXi + VM_SLC + VM_Core) into Orion Solarwinds
 
.DESCRIPTION
  Requires SwisPowershell module and PowerOrion PowerShell module

  https://github.com/solarwinds/OrionSDK/wiki/PowerShell
  https://github.com/solarwinds/OrionSDK/wiki/PowerOrion---A-Module-for-PowerShell
  https://github.com/solarwinds/OrionSDK/tree/master/Samples/PowerShell
    
.NOTES
  Authors:        user10, Richard Smith

.HISTORY
  Version:        1.0 (2020-04-29)
  Purpose/Change: Initial Script Creation

.FUNCTIONALITY
    Requires SwisPowershell module and PowerOrion PowerShell module

      https://github.com/solarwinds/OrionSDK/wiki/PowerShell
      https://github.com/solarwinds/OrionSDK/wiki/PowerOrion---A-Module-for-PowerShell
      https://github.com/solarwinds/OrionSDK/tree/master/Samples/PowerShell

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################

$Script:ProductName = "OrionSolarWinds" 
$ErrorActionPreference = "SilentlyContinue" 

# Import SwisPowerShell module
# -------------------------------
Try{
    Import-Module SwisPowerShell -ErrorAction "Stop"
}
catch{
    Write-Host "SwisPowerShell module not found. Installing..."
    Install-Module -Name SwisPowerShell
}
$ErrorActionPreference = "Continue"

# Import PowerOrion PowerShell module
# -------------------------------
Try{
    Import-Module PowerOrion -ErrorAction "Stop"
}
Catch{
    Write-Host "PowerOrion powershell module is not installed. This script cannot continue"
    Write-Host "Download module here: https://github.com/solarwinds/OrionSDK/wiki/PowerOrion---A-Module-for-PowerShell"
    Start-Sleep -Seconds 20
    Exit
}
$ErrorActionPreference = "Continue"

Clear-Host

# Credentials; Target File; Region Assignments
# -------------------------------
$swis = Connect-Swis -Certificate
#$swis = Connect-Swis -UserName 'domain\sysadmin' 
#$strnmbr = Read-Host -Prompt "Enter UFO_NUMBER"
$targetList = Get-Content "C:\temp\01-targets.txt"
$regioncode = $strnmbr.Substring(0,1)
If ($regioncode -eq 1){$region = "US"}
If ($regioncode -eq 2){$region = "Canada"}
If ($regioncode -eq 3){$region = "Australia"}

Write-Host "Region value set to $region" -ForegroundColor Yellow

Try{
    $u = $strnmbr + "str"
    $usr = get-aduser -Identity $u -Properties *
    $addr = $usr.StreetAddress
    $state = $usr.State
    $city = $usr.City
    $zip = $usr.PostalCode
    $phone = $usr.telephoneNumber
    }

    Catch{
        Write-Host "No Address Information for store #$strnmbr exists in AD. Skipping..." -ForegroundColor Cyan
    }


# Functions
#################################

FUNCTION Log_ToSplunk
{
 [CmdletBinding()]
 Param
 (
   [parameter(Mandatory=$true,
   Position=0)]
   $Message,

   [parameter(Mandatory=$false,
   Position=1)]
   $Type = "Log",

   [parameter(Mandatory=$false,
   Position=2)]
   $Status = "Informational",

   [parameter(Mandatory=$false,
   Position=3)]
   $ID = $Null
 )

 $product = "team_" + $Script:ProductName
 $uri = "https://hecext.example.com:18443/services/collector/event"
 $header = @{}
 $header.add('Content-Type', 'application/json')
 $header.add('Authorization', 'Splunk Application-Key-Here')
 $body = @{
     sourcetype = 'domain:ps:log'
     host = $env:COMPUTERNAME
     event = @{
         message = $Message
         user = $env:USERNAME
         product = $Product
         type = $Type
         status = $Status
         id = $ID
     }
 }
 $body = $body | ConvertTo-Json
 Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}
# -------------------------------

FUNCTION Get-StoreIPs{
    Param(
    [parameter(Mandatory=$true,Position=0)]
    [string]$UFO_NUMBER
    )

    # Sets 2nd & 3rd IP address octets based on store #
    $oct2a = $UFO_NUMBER.Substring(0,1)
    $oct2b = $UFO_NUMBER.Substring(1,1)
    $oct3a = $UFO_NUMBER.Substring(2,1)
    $oct3b = $UFO_NUMBER.Substring(3,1)

    if($oct2a -gt 0){$oct2 = ("$oct2a" + "$oct2b")} else { $oct2 = "$oct2b"}
    if($oct3a -gt 0){$oct3 = ("$oct3a" + "$oct3b")} else { $oct3 = "$oct3b"}

    # Generate store server breakdown IP addresses
    $global:iDracip = "10."+"$oct2."+"$oct3."+"99"
    $global:ESXip = "10."+"$oct2."+"$oct3."+"98"
    $global:SLCip = "10."+"$oct2."+"$oct3."+"10"
    $global:Coreip = "10."+"$oct2."+"$oct3."+"9"

    "iDrac $iDracip"
    "ESXi $ESXip"
    "VM_SLC $SLCip"
    "VM_Core $Coreip"
}

FUNCTION Add-OrionNode{
    Param(
    [parameter(Mandatory=$true,Position=0)]
    $ip,
    [parameter(Mandatory=$true,Position=0)]
    $credentialid
    )

# Test connectivity status with device, skip if offline.
If((Test-Connection $ip -Quiet) -ne $true){
    Write-Host "$ip is not online, skipping..." -ForegroundColor Red
    }
    
    Else{
        Write-Host "$ip is Online." -ForegroundColor Cyan

# Credential ID notes: Use Credential ID #6 for Juniper switches and ID #17 for Meraki devices
$CorePluginConfigurationContext = ([xml]"
<CorePluginConfigurationContext xmlns='http://schemas.solarwinds.com/2012/Orion/Core' xmlns:i='http://www.w3.org/2001/XMLSchema-instance'>
    <BulkList>
        <IpAddress>
            <Address>$ip</Address>
        </IpAddress>
    </BulkList>
    <Credentials>
        <SharedCredentialInfo>
            <CredentialID>$credentialid</CredentialID>
            <Order>1</Order>
        </SharedCredentialInfo>
    </Credentials>
    <WmiRetriesCount>1</WmiRetriesCount>
    <WmiRetryIntervalMiliseconds>1000</WmiRetryIntervalMiliseconds>
</CorePluginConfigurationContext>
").DocumentElement

$CorePluginConfiguration = Invoke-SwisVerb $swis Orion.Discovery CreateCorePluginConfiguration @($CorePluginConfigurationContext)

$InterfacesPluginConfigurationContext = ([xml]"
<InterfacesDiscoveryPluginContext xmlns='http://schemas.solarwinds.com/2008/Interfaces' xmlns:a='http://schemas.microsoft.com/2003/10/Serialization/Arrays'>
    <AutoImportStatus>
        <a:string>Up</a:string>
        <a:string>Down</a:string>
        <a:string>Shutdown</a:string>
    </AutoImportStatus>
    <AutoImporDomainrtualTypes>
        <a:string>Virtual</a:string>
        <a:string>Physical</a:string>
    </AutoImporDomainrtualTypes>
    <AutoImportVlanPortTypes>
        <a:string>Trunk</a:string>
        <a:string>Access</a:string>
        <a:string>Unknown</a:string>
    </AutoImportVlanPortTypes>
    <UseDefaults>false</UseDefaults>
</InterfacesDiscoveryPluginContext>
").DocumentElement

$InterfacesPluginConfiguration = Invoke-SwisVerb $swis Orion.NPM.Interfaces CreateInterfacesPluginConfiguration @($InterfacesPluginConfigurationContext)

$EngineID = 1
$DeleteProfileAfterDiscoveryCompletes = "true"

$StartDiscoveryContext = ([xml]"
<StartDiscoveryContext xmlns='http://schemas.solarwinds.com/2012/Orion/Core' xmlns:i='http://www.w3.org/2001/XMLSchema-instance'>
    <Name>Script Discovery $([DateTime]::Now)</Name>
    <EngineId>$EngineID</EngineId>
    <JobTimeoutSeconds>3600</JobTimeoutSeconds>
    <SearchTimeoutMiliseconds>2000</SearchTimeoutMiliseconds>
    <SnmpTimeoutMiliseconds>2000</SnmpTimeoutMiliseconds>
    <SnmpRetries>3</SnmpRetries>
    <RepeatIntervalMiliseconds>1500</RepeatIntervalMiliseconds>
    <SnmpPort>161</SnmpPort>
    <HopCount>0</HopCount>
    <PreferredSnmpVersion>SNMP3</PreferredSnmpVersion>
    <DisableIcmp>false</DisableIcmp>
    <AllowDuplicateNodes>false</AllowDuplicateNodes>
    <IsAutoImport>true</IsAutoImport>
    <IsHidden>$DeleteProfileAfterDiscoveryCompletes</IsHidden>
    <PluginConfigurations>
        <PluginConfiguration>
            <PluginConfigurationItem>$($CorePluginConfiguration.InnerXml)</PluginConfigurationItem>
            <PluginConfigurationItem>$($InterfacesPluginConfiguration.InnerXml)</PluginConfigurationItem>
        </PluginConfiguration>
    </PluginConfigurations>
</StartDiscoveryContext>
").DocumentElement

$DiscoveryProfileID = (Invoke-SwisVerb $swis Orion.Discovery StartDiscovery @($StartDiscoveryContext)).InnerText

Write-Host "Adding store server item $ip to Orion for UFO_NUMBER $strnmbr. Please wait..." -ForegroundColor Yellow
do {
    Start-Sleep -Seconds 1
    $Status = Get-SwisData $swis "SELECT Status FROM Orion.DiscoveryProfiles WHERE ProfileID = @profileId" @{profileId = $DiscoveryProfileID}
} while ($Status -eq 1)

    $Result = Get-SwisData $swis "SELECT Result, ResultDescription, ErrorMessage, BatchID FROM Orion.DiscoveryLogs WHERE ProfileID = @profileId" @{profileId = $DiscoveryProfileID}
    }
}

# Set custom node properties in Orion
Function Set-OrionNodeCustomProperty
{
    Param(
    [parameter(Mandatory=$true,Position=0)]
    $ip,
    [parameter(Mandatory=$true,Position=1)]
    [string]$devicetype,
    [parameter(Mandatory=$false,Position=2)]
    [string]$connectiontype,
    [parameter(Mandatory=$true,Position=3)]
    [string]$region,
    [parameter(Mandatory=$true,Position=4)]
    [string]$UFO_NUMBER
    )

    If((Test-Connection $ip -Quiet) -eq $true){
        Write-Host "Setting Custom Property Values for $ip" -ForegroundColor Yellow
        $nodeCustomPropertiesUri = (Get-OrionNode -IPAddress $ip -SwisCOnnection $swis -custom).Uri 
        Set-SwisObject $swis $nodeCustomPropertiesUri @{ Device_Type = $devicetype; Region = "$region"; UFO_NUMBER = "$UFO_NUMBER"; Address = "$addr"; Phone = "$phone"; State_Province = "$state"; Zip = "$zip" }
        }
}

# Script Starts
#################################

foreach ($strnmbr in $targetList){
Get-StoreIPs -UFO_NUMBER $strnmbr

Add-OrionNode -ip $global:iDracip -credentialid 6
Add-OrionNode -ip $global:ESXip -credentialid 6
Add-OrionNode -ip $global:SLCip -credentialid 6
Add-OrionNode -ip $global:Coreip -credentialid 6

Set-OrionNodeCustomProperty -ip $global:iDracip -devicetype "iDrac" -region $region -UFO_NUMBER "$strnmbr"
Set-OrionNodeCustomProperty -ip $global:ESXip -devicetype "ESXi" -region $region -UFO_NUMBER "$strnmbr"
Set-OrionNodeCustomProperty -ip $global:SLCip -devicetype "VM_SLC" -region $region -UFO_NUMBER "$strnmbr"
Set-OrionNodeCustomProperty -ip $global:Coreip -devicetype "VM_Core" -region $region -UFO_NUMBER "$strnmbr"
Write-Host ""
Write-Host "Script completed.  Please verify nodes in Orion."
}
# Script Ends
#################################
Exit