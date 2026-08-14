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
    Add-OrionStoreNodes2020.ps1

.SYNOPSIS
  Orion Solarwinds Node management
 
.DESCRIPTION

Need functionality to add bulk list of stores
Integrate into script that adds stores
Add functionality to check if node already exists

  Requires SwisPowershell module and PowerOrion PowerShell module

  https://github.com/solarwinds/OrionSDK/wiki/PowerShell
  https://github.com/solarwinds/OrionSDK/wiki/PowerOrion---A-Module-for-PowerShell
  https://github.com/solarwinds/OrionSDK/tree/master/Samples/PowerShell

    ----------------------------------
    - Polling Engine EngineID Values -
    ----------------------------------
    Hostname     IP address   EngineID
    --------     ----------   --------
    PC0-CDE-NMS1 0.0.0.0        1
    PC0-CDE-NMS2 0.0.0.0        2
    ----------------------------------
    -      Credential ID notes       -
    ----------------------------------
    All ICMP only                    6
    Juniper Switch Credential ID     6
    Meraki Device Credential  ID    17
    ----------------------------------
.EXAMPLE

.NOTES
  Version:        1.2
  Author:         user10
  Creation Date:  08/18/2020
  Purpose/Change: 
    - Added ability to set txt input file 
    - Updated the 'UFO_NUMBER' column input value to match the new value of 'UFO_NUMBER'
    - Set default polling engine value to '2' after SW server redeployment, following ransomware attack.
.HISTORY
  Version:        1.1 (05/09/2020)
  Author:         user10
  Purpose/Change: 
    - Added logging 
    - Fixed issue where city wasn't added to custom attributes
    - Set default polling engine to PC0-CDE-NMS2 0.0.0.0  value: 5
 
  Version:        1.0 (5/7/2019)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Need functionality to add bulk list of stores
    Integrate into script that adds stores
    Add functionality to check if node already exists

      Requires SwisPowershell module and PowerOrion PowerShell module

      https://github.com/solarwinds/OrionSDK/wiki/PowerShell
      https://github.com/solarwinds/OrionSDK/wiki/PowerOrion---A-Module-for-PowerShell
      https://github.com/solarwinds/OrionSDK/tree/master/Samples/PowerShell

        ----------------------------------
        - Polling Engine EngineID Values -
        ----------------------------------
        Hostname     IP address   EngineID
        --------     ----------   --------
        PC0-CDE-NMS1 0.0.0.0        1
        PC0-CDE-NMS2 0.0.0.0        2
        ----------------------------------
        -      Credential ID notes       -
        ----------------------------------
        All ICMP only                    6
        Juniper Switch Credential ID     6
        Meraki Device Credential  ID    17
        ----------------------------------

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#################################
# Initializations
#################################
[cmdletbinding()]

param
(
    [string]$strnmbr,
    [string]$storelist
)

$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:ProductName = "AddOrionAPNodes"
$ErrorActionPreference = "SilentlyContinue"
$script:Logfile = "$script:script_dir\logs\$Script:ProductName.txt"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
Import-Module SwisPowerShell
Import-Module PowerOrion
$script:swis = Connect-Swis -Certificate
#################################
# Functions
#################################
Function Log_ToSplunk
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
}#------------[END Log_ToSplunk]------------
Function Append-Log($message)
{   
    $thetime = Get-Date -Format g
    "$thetime`: $message" | Out-File $Script:Logfile -Append
}#---------[END Append-Log]---------
Function Get-RegionCode
{
    Param(
    [parameter(Mandatory=$true,Position=0)]
    [string]$UFO_NUMBER
    )
    $regioncode = $strnmbr.Substring(0,1)
    If ($regioncode -eq 1){$script:region = "US"}
    If ($regioncode -eq 2){$script:region = "Canada"}
    If ($regioncode -eq 3){$script:region = "Australia"}
    $output = "Region value set to $region"
    Write-Host $output -ForegroundColor White
    Append-Log $output
    #Log_ToSplunk -Message $output
}#------------[END Get-RegionCode]------------
Function Get-StoreIPs
{
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
    # Generate store network device IP addresses
    $script:FWip = "10."+"$oct2."+"$oct3."+"193"
    $script:MSWip = "10."+"$oct2."+"$oct3."+"226"
    $script:RSWip = "10."+"$oct2."+"$oct3."+"227"
    $a = (1..9)
    $a | ForEach-Object {
        $apname = "AP" + $_
        $apip = "AP" + $_ + "ip"
        $ipvalue = "10."+"$oct2."+"$oct3."+"23" + $_
        $namevalue = $UFO_NUMBER +  "-AP" + $_
        New-Variable $apip $ipvalue -Scope "script" -Force
        New-Variable $apname $namevalue -Scope "script" -Force
        if(Test-Connection -ComputerName $ipvalue -Count 1 -ErrorAction SilentlyContinue)
        {
            $output = "$namevalue ($ipvalue) is online.  Proceeding with processing this AP node in Orion..."
            Write-Host $output -ForegroundColor Green
            Append-Log $output
            #Log_ToSplunk -Message $output
            Add-OrionNode -ip $ipvalue -credentialid 6
            Set-OrionNodeProperties -apname $namevalue -ip $ipvalue -swis $swis
            Set-OrionNodeCustomProperty -ip $ipvalue -devicetype "AP" -region $script:region -UFO_NUMBER $UFO_NUMBER
        }
    }
    $output = "Completed processing AP nodes in Orion: Access Point IP range ($ap1`:$ap9): $ap1ip - $ap9ip"
    Write-Host $output -ForegroundColor White
    Append-Log $output
    #Log_ToSplunk -Message $output
}#------------[END Get-StoreIPs]------------
Function Set-OrionNodeProperties($apname,$ip,$swis)
{
    Try
    {
        $nodePropertiesUri = (Get-OrionNode -IPAddress $ip -SwisConnection $swis).Uri
        Set-SwisObject $swis $nodePropertiesUri @{NodeName = $apname} -ErrorAction Stop
        $newname = (Get-OrionNode -IPAddress $ip -SwisConnection $swis).NodeName
        $output = "Successfully set the 'NodeName' property for $ip to $apname.`nNodeName: $newname | IP Address: $ip"
        Write-Host $output -ForegroundColor Green
        #Log_ToSplunk -Message $output
    }
        Catch
        {
            $output = "ERROR: Failed to set the 'NodeName' property for $ip. Exception Message: $($_.Exception.Message)."
            Write-Host $output -ForegroundColor Red
            #Log_ToSplunk -Message $output
        }
        Finally
        {
            Append-Log $output
            $ErrorActionPreference = "SilentlyContinue"
        }
}#------------[END Set-OrionNodeProperties]------------
Function Add-OrionNode
{
    Param(
    [parameter(Mandatory=$true,Position=0)]$ip,
    [parameter(Mandatory=$false,Position=0)]$credentialid
    )
# Test connectivity status with network device, skip if offline.

If((Test-Connection $ip -Quiet) -ne $true)
{
    $output = "$ip is not online, skipping..."
    Write-Host $output -ForegroundColor White
    Append-Log $output
    #Log_ToSplunk -Message $output
}
    Else{
# Credential ID notes: Use Credential ID #6 for all(ICMP only), ID #6 for Juniper switches (SNMPv3) and ID #10 for Meraki devices (SNMPv3).

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
<# 
    Polling Engine EngineID Values:

    Hostname     IP address   EngineID
    --------     ----------   --------
    PC0-CDE-NMS1 0.0.0.0    1
    PC0-CDE-NMS2 0.0.0.0    2
#>
$EngineID = 2 #PC0-CDE-NMS2
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
$output = "Adding network device $ip to Orion for UFO_NUMBER $strnmbr. Please wait..."
Write-Host $output -ForegroundColor White
Append-Log $output
#Log_ToSplunk -Message $output
do {
    Start-Sleep -Seconds 1
    $Status = Get-SwisData $swis "SELECT Status FROM Orion.DiscoveryProfiles WHERE ProfileID = @profileId" @{profileId = $DiscoveryProfileID}
} while ($Status -eq 1)

    $Result = Get-SwisData $swis "SELECT Result, ResultDescription, ErrorMessage, BatchID FROM Orion.DiscoveryLogs WHERE ProfileID = @profileId" @{profileId = $DiscoveryProfileID}
    }
}#------------[END Add-OrionNode]------------
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
        Write-Host "Setting Custom Property Values for $ip" -ForegroundColor White
        $nodeCustomPropertiesUri = (Get-OrionNode -IPAddress $ip -SwisCOnnection $swis -custom).Uri 
        Set-SwisObject $swis $nodeCustomPropertiesUri @{ Device_Type = $devicetype; Connection_Type = "$connectiontype"; Region = "$script:region"; UFO_NUMBER = "$UFO_NUMBER"; Address = "$addr"; Phone = "$phone"; State_Province = "$state"; City = "$city" ;Zip = "$zip" }
        }
}#------------[END Set-OrionNodeCustomProperty]------------
Function Get-ADAttributes($UFO_NUMBER)
{
    Try
    {
        $u = $UFO_NUMBER + "str"
        $usr = get-aduser -Identity $u -Properties * -ErrorAction Stop
        $script:addr = $usr.StreetAddress
        $script:state = $usr.State
        $script:city = $usr.City
        $script:zip = $usr.PostalCode
        $script:phone = $usr.telephoneNumber
        $output = "Located store address information for store #$strnmbr in Active Directory. Adding store address attributes to Orion..."
        Write-Host $output
        Append-Log $output
    }
        Catch
        {
            $output = "No Store address information for store #$strnmbr found in Active Directory. Skipping store address attribute addition to Orion."
            Write-Host $output
            Append-Log $output
        }
}#------------[END Get-ADAttributes]------------
#################################
# Script Begins
#################################
### Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational" - (5/7/2019-user2) Commented out until Splunk server is accessible from CDE.
Append-Log "Script Starting"
Clear-Host
if($storelist)
{
    if(!(Test-Path $storelist))
    {
        Write-Host "$storelist not found. Please try a different path." -ForegroundColor Cyan
    }
        else
        {
            Write-Host "Processing $storelist" -ForegroundColor Green
            $inputlist = Get-Content $storelist
            $inputlist | 
            ForEach-Object{
                    $strnmbr = $_
                    Write-Host "Processing $strnmbr" -ForegroundColor Green
                    Get-ADAttributes -UFO_NUMBER $strnmbr
                    Get-RegionCode -UFO_NUMBER $strnmbr
                    Get-StoreIPs -UFO_NUMBER $strnmbr                    
                }
        }
}
elseif($strnmbr)
{
    Write-Host "Processing $strnmbr" -ForegroundColor Green
    Get-ADAttributes -UFO_NUMBER $strnmbr
    Get-RegionCode -UFO_NUMBER $strnmbr
    Get-StoreIPs -UFO_NUMBER $strnmbr    
}
    else
    {
        $strnmbr = Read-Host "Enter UFO_NUMBER"
        Write-Host "Processing $strnmbr" -ForegroundColor Green
        Get-ADAttributes -UFO_NUMBER $strnmbr
        Get-RegionCode -UFO_NUMBER $strnmbr
        Get-StoreIPs -UFO_NUMBER $strnmbr
    }
# Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational" - (5/7/2019-user2) Commented out until Splunk server is accessible from CDE.
Append-Log "Script Ending"
" " | Out-File $Script:Logfile -Append
Exit
#################################
# Script Ends
#################################