# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Setup-Host.ps1

.SYNOPSIS
  Script used to setup esxi hosts for stores
 
.DESCRIPTION
  This script does the following:
    *Adds ESXi host DNS entry to DNS server
    *Adds DNS server addresses to the target ESXi host
    *Clears and then creates datastore on the target ESXi host
    *Joins target ESXi host to vCenter
    *Deploys store VM templates to target ESXi host
    *Creates VMs from templates on target ESXi host
    *Sets VMs to auto-start on target ESXi host
    *Sets NTP server on target ESXi host
  
.NOTES
  Version:        1.0
  Author:         user22
  Creation Date:  09/26/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0 
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    This script does the following:
        *Adds ESXi host DNS entry to DNS server
        *Adds DNS server addresses to the target ESXi host
        *Clears and then creates datastore on the target ESXi host
        *Joins target ESXi host to vCenter
        *Deploys store VM templates to target ESXi host
        *Creates VMs from templates on target ESXi host
        *Sets VMs to auto-start on target ESXi host
        *Sets NTP server on target ESXi host

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "Setup-Host" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "Inquire" #Maybe change to "SilentlyContinue" for Production.
Install-Module -Name "Posh-SSH" -Force
Import-Module -Name "Posh-SSH" -Force

# Functions
#################################
function Log_ToSplunk
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

	$SB = {
		param($uri,$header,$body)
		Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
	}

	$job = Start-Job -scriptblock $SB -argumentlist @($uri,$header,$body)
	$timeout = 10
	Wait-Job $job -Timeout $timeout
	Stop-Job $job
	Receive-Job $job
	Remove-Job $job
}

function add_dnsentry
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $HostName,

        [parameter(Mandatory=$true,
        Position=1)]
        $IP
    )

    $DC = "SRV-ADS-DC16"
    $adddnsrecord =
    {
        $IP = $args[0]
        $HostName = $args[1]
        Add-DnsServerResourceRecord -ZoneName "example.com" -IPv4Address $IP -A -TimeToLive "01:00:00" -Name $HostName
    }
    $removednsrecord =
    {
        $Hostname = $args[0]
        Get-DnsServerResourceRecord -ZoneName "example.com" | Where-Object {$_.HostName -eq "$($HostName)"} | Remove-DnsServerResourceRecord -Force -ZoneName "example.com"
    }

    #checks to see if entry needs to be modified or created
    $existingEntries = invoke-command -scriptblock {Get-DnsServerResourceRecord -ZoneName example.com} -ComputerName $DC -Credential $script:credential | Where-Object {$_.HostName -eq "$($HostName)"}

    #$creatednsentry = Add-DnsServerResourceRecord -ZoneName "example.com" -IPv4Address $IP -A -TimeToLive "01:00:00" -Name $HostName
    if(($existingEntries.HostName) -eq $Null)
    {
        Invoke-Command -ComputerName $DC -ScriptBlock $adddnsrecord -ArgumentList $IP,$HostName -Credential $script:credential
        if($?)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    else
    {
        Write-Host "Existing DNS entries found for $($hostname), removing before continuing." -ForegroundColor Yellow
        Log_ToSplunk -Message "Existing DNS entries found for $($hostname), removing before continuing."
        #$command = Get-DnsServerResourceRecord -ZoneName "example.com" | Where-Object {$_.HostName -eq "$($HostName)"} | Remove-DnsServerResourceRecord -Force -ZoneName "example.com"
        Invoke-Command -ComputerName $DC -ScriptBlock $removednsrecord -ArgumentList $HostName -Credential $script:credential
        if($?)
        {
            Log_ToSplunk -Message "Existing DNS entries removed for $($hostname)"
            Write-Host "Existing DNS entries removed for $($hostname), proceeding to create new entry"

            Invoke-Command -ComputerName $DC -ScriptBlock $adddnsrecord -ArgumentList $IP,$HostName -Credential $script:credential
            if($?)
            {
                return $true
            }
            else
            {
                return $false
            }
        }
    }
}

function Initialize_PowerCLI
{
    if(Get-Command -Name "Get-VIServer")
    {
        Continue
    }
    else
    {
        Write-Host "VMware PowerCLI was not found! Please install VMware PowerCLI BEFORE running this script!!!!!!" -ForegroundColor Red
        Exit
    }
}

# function derived from script found here: http://www.vhersey.com/2013/10/31/setting-esxi-dns-and-ntp-using-powercli/
function Set_DNSandNTP
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $esxTarget,

        [parameter(Mandatory=$true,
        Position=1)]
        $esxHostName
    )
    #static information
    $dnspri = "0.0.0.0"
    $dnsalt = "0.0.0.0"
    $domain = "example.com"
    $ntppri = "0.0.0.0"

    Write-Host "Configuring DNS, Host Name and Domain Name on $esxTarget"
    Get-VMHostNetwork -VMHost $esxTarget | Set-VMHostNetwork -HostName $esxHostName -DomainName $domain -DnsAddress $dnspri,$dnsalt -Confirm:$false
    Write-Host "Configuring NTP Servers on $esxTarget"
    Add-VMHostNtpServer -NtpServer $ntppri -VMHost $esxTarget -Confirm:$false
    Write-Host "Configuring NTP Client Policy on $esxTarget"
    Get-VMHostService -VMHost $esxTarget | Where-Object {$_.Key -eq "ntpd"} | Set-VMHostService -Policy "on" -Confirm:$false
    Write-Host "Restarting NTP Client on $esxTarget"
    Get-VMHostService -VMHost $esxTarget | Where-Object {$_.Key -eq "ntpd"} | Restart-VMHostService -Confirm:$false
    Log_ToSplunk -Message "Host Name, DNS and NTP setup on $esxHostName"
}

function Join_VCenter
{
    [CmdletBinding()]
    param 
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $esxTarget,

        [parameter(Mandatory=$true,
        Position=0)]
        $esxHostName
    )

    $user = "root"
    $pass = ConvertTo-SecureString '<password>' -AsPlainText -Force
    $cred = new-object System.Management.Automation.PSCredential($user,$pass)

    # get folder location to place server
    if(($script:storeNum.substring(0,1) -eq "1") -or ($script:storeNum.substring(0,1) -eq "5") -or ($script:storeNum.substring(0,1) -eq "8"))
    {
        Write-Host "Location set to 'United States' based on provided UFO_NUMBER."
        $location = Get-Folder -Server $script:vCenter | Where-Object {$_.Name -eq "United States"}
    }
    if($script:storeNum.substring(0,1) -eq "2")
    {
        Write-Host "Location set to 'Canada' based on provided UFO_NUMBER."
        $location = Get-Folder -Server $script:vCenter | Where-Object {$_.Name -eq "Canada"}
    }
    if($script:storeNum.substring(0,1) -eq "3")
    {
        Write-Host "Location set to 'Australia' based on provided UFO_NUMBER."
        $location = Get-Folder -Server $script:vCenter | Where-Object {$_.Name -eq "Australia"}
    }
    
    # Add host to vcenter
    Add-VMHost -Name $($esxHostName+".example.com") -Location $location -Credential $cred -Force
    if($?)
    {
        Write-Host "$esxHostName succesfully added to vCenter" -ForegroundColor Green
        Log_ToSplunk -Message "$esxHostName succesfully added to vCenter"
    }
    else 
    {
        Write-Host "$esxHostName could not be added to vCenter" -ForegroundColor Red
        Log_ToSplunk -Message "$esxHostName could not be added to vCenter" -Status "fail"
    }
}

function Create_Datastore 
{
    $datastores = Get-Datastore -Server $script:esxHost
    if($datastores.count -gt "0")
    {
        Write-Host "Removing $($datastores.count) existing datastores before creating new one."
        foreach($datastore in $datastores)
        {
            Remove-Datastore -Server $script:esxHost -Datastore $datastore -Confirm:$false
        }
    }

    $targetInt = Get-ScsiLun -Server $script:esxHost -LunType disk | Select CanonicalName,CapacityGB | Where-Object {$_.CapacityGB -gt "100"}
    New-Datastore -Server $script:esxHost -Vmfs -Name $("Datastore"+$script:storeNum) -Path $targetInt.CanonicalName -Confirm:$false
    Write-Host "New datastore created"
    Get-VMHostStorage -Server $script:esxHost -RescanAllHba | Out-Null
}

function Copy_Template
{
    $datastore = Get-Datastore -Server $script:vCenter -Name $("Datastore"+$script:storeNum)
    New-PSdrive -Location $datastore -Name DS -PSProvider VimDatastore -Root "\"
    $templates = Get-Template -Server $script:vCenter -Location "TDX-VSP-ESX01.example.com"
    foreach($template in $templates)
    {
        if($template.Name -like "*SLC*")
        {
            $folder = Get-Folder -Server $script:vCenter -Name "VM"
            New-Template -Name $($script:storeNum+"SLC_Template") -Datastore $datastore -Template $template -Location $folder
        }
        if($template.Name -like "*CORE*")
        {
            $folder = New-Item -Path "DS:\$script:storeNum`CORE_Template" -ItemType Directory -Force
            New-Template -Name $($script:storeNum+"CORE_Template") -Datastore $datastore -Template $template -Location $folder
        }
    }
    Remove-PSDrive -Name DS -Force
}

function Deploy_VM
{
    $templates = Get-Template -Server $script:vCenter -Location $($script:esxHost.Name+".example.com")
    $datastore = Get-Datastore -Server $script:esxHost -Name $("Datastore"+$script:storeNum)
    foreach($template in $templates)
    {
        if($template.Name -like "*SLC*")
        {
            New-VM -Name $($script:storeNum+"SLC1") -Template $template -Datastore $datastore
        }
        if($template.Name -like "*CORE*")
        {
            New-VM -Name $($script:storeNum+"CORE") -Template $template -Datastore $datastore
        }
    }
}

function Enable_SSH
{
    Get-VMHost -Name $script:esxHost | foreach{Start-VMHostService -HostService ($_ | Get-VMHostService | Where {$_.Key -eq "TSM-SSH"})}
}

function Disable_SSH
{
    Get-VMhost -Name $script:esxHost | foreach{Stop-VMHostService -HostService ($_ | Get-VMHostService | Where {$_.Key -eq "TSM-SSH"})}
}

function Clear_PartitionTable
{
    [CmdletBinding()]
    param 
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $esxTarget
    )
    $targetDisk = (Get-ScsiLun -Server $script:esxHost -LunType disk | select consoledevicename,capacitygb | Where-Object {$_.CapacityGB -gt "100"}).consoledevicename
    $sshuser = "root"
    $sshpass = ConvertTo-SecureString '<password>' -AsPlainText -Force
    $sshcred = new-object System.Management.Automation.PSCredential($sshuser,$sshpass)
    $ssh = New-SSHSession -IPAddress $esxTarget -Credential $sshcred -Force
    Invoke-SSHCommand -SSHSession $ssh -Command "partedUtil delete $targetDisk 1"
    Invoke-SSHCommand -SSHSession $ssh -Command "partedUtil delete $targetDisk 2"
    Invoke-SSHCommand -SSHSession $ssh -Command "partedUtil delete $targetDisk 3"
    Invoke-SSHCommand -SSHSession $ssh -Command "PartedUtil fix $targetDisk"
    Get-VMHostStorage -Server $script:esxHost -RescanAllHba | Out-Null
}

# Variables
#################################

# Below used to get, and check credentials
$flag = 1;
do
{
    Write-Host "Enter Admin Credentials" -ForegroundColor Yellow
    $username = Read-Host "Enter Admin Username"
    $password = Read-Host "Enter Password" -AsSecureString
    $script:credential = New-Object -TypeName System.Management.Automation.PSCredential($username,$password)

    $usercheck = $script:credential.UserName
    $passcheck = $script:credential.GetNetworkCredential().Password

    $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
    $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$usercheck,$passcheck)

    if($domain.Name -eq $null)
    {
        Clear-Host
        Write-Host "Credentials invalid, please try again." -ForegroundColor Red
    }
    else 
    {
        $flag = 0;
    }
}
while($flag -eq 1)

# connect to vcenter, aborts if connection fails
$script:vCenter = Connect-VIServer -Server "SRV-VSP-VC11" -Credential $script:credential -Force
if($script:vCenter -ne $null)
{
    Write-Host "Established connection to vCenter on SRV-VSP-VC11 succesfully." -ForegroundColor Green
}
else 
{
    Write-Host "Unable to establish connection to vCenter. Aborting" -ForegroundColor Red
    exit
}

# connects to tdx host
$script:tdxHost = Connect-VIServer -Server "tdx-vsp-esx01" -Protocol https -User "root" -Password '<password>'
if($script:tdxHost -ne $null)
{
    Write-Host "Established connection to TDX vmHost succesfully." -ForegroundColor Green
}
else 
{
    Write-Host "Unable to establish connection to TDX vmHost. Aborting" -ForegroundColor Red
    exit
}

# connects to target host
$esxTarget = Read-Host "Enter IP Address of Target Host"
$script:esxHost = Connect-VIServer -Server $esxTarget -Protocol https -User "root" -Password '<password>'
if($script:esxHost -ne $null)
{
    Write-Host "Established connection to target host ($esxTarget) succesfully." -ForegroundColor Green
}
else 
{
    Write-Host "Unable to establish connection to target host. Aborting" -ForegroundColor Red
    exit
}

# gets UFO_NUMBER and has user confirm
$flag = 1;
do
{
    $script:storeNum = Read-Host "Enter UFO_NUMBER"
    Write-Host "UFO_NUMBER for this host will be $script:storeNum, is this correct? (y/n)"
    $response = Read-Host
    if($response -eq "y")
    {
        $flag = 0;
    }
}
while($flag -eq 1)

# creates target hostname based on provided UFO_NUMBER
$esxHostName = $script:storeNum + "esxi"

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

Initialize_PowerCLI
add_dnsentry -HostName $esxHostName -IP $esxTarget
Set_DNSandNTP -esxTarget $esxTarget -esxHostName $esxHostName
Enable_SSH
Clear_PartitionTable -esxTarget $esxTarget
Disable_SSH
Create_Datastore
Join_VCenter -esxTarget $esxTarget -esxHostName $esxHostName
Copy_Template
Deploy_VM
Disconnect-VIServer -Server * -Confirm:$false

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit