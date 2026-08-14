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
    Set-HostProfiles_2.ps1

.SYNOPSIS
  Makes Changes to ESXIhosts
 
.DESCRIPTION
  This script can be used in leiu of using Host Profiles. Will make changes against EVERY host in
    the connected vCenter.

.EXAMPLE
  If this script can be called from the command line, show exampls here
  
.NOTES
  Version:        1.1
  Author:         user26
  Creation Date:  05/02/2018
  Purpose/Change: Added Set NTP and Syslog.

.HISTORY
  Version:        1.0 (05/02/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    This script can be used in leiu of using Host Profiles. Will make changes against EVERY host in
        the connected vCenter.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
##Requires -Modules vmware.powercli
$Script:ProductName = "SetRetailHostProfiles" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "Inquire" #Maybe change to "SilentlyContinue" for Production.
Clear-Host
Write-Host "Loading PowerCLI Module Now." -ForegroundColor Green
Import-Module vmware.powercli

# Variables
#################################
$vCenter = "SRV-VSP-VC11.example.com"
$ntpservers = "0.0.0.0"

# NTP URL is Time.example.com (with a VIP of 0.0.0.0), and is load balanced off the A10.

# Functions
#################################
function Log_ToSplunk{
    Param(
    [parameter(Mandatory=$true,
    Position=0)]
    [String]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    [String]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    [String]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
    [int]
    $ID = $Null
    )

    $product = "sysops_" + $Script:ProductName
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

Function Set-ESXiNTPServer($ESXiHost,$NTP){
    $configuredServers = Get-VMHostNtpServer -VMHost $ESXiHost

    if(!$configuredServers){
        Clear-Host
        Write-Host "ESXiHost $($ESXiHost) did not have an NTP server(s). Adding NTP server(s): $($NTP)." -ForegroundColor Green
        Add-VmHostNtpServer -NtpServer $NTP -VMHost $ESXiHost | Out-Null
        Get-VMHostService -VMHost $ESXiHost | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "on" -Confirm:$false
        Get-VmHostService -VMHost $ESXiHost | Where-Object {$_.key -eq "ntpd"} | Restart-VMHostService -Confirm:$false | Out-Null
        Log_ToSplunk -Message "ESXiHost $($ESXiHost) did not have an NTP server(s). Added NTP server(s): $($NTP)." -Type "Log" -Status "Informational"
    }
    ElseIf($ConfiguredServers -ne $NTP){
        Clear-Host
        Write-Host "ESXiHost $($ESXiHost) had incorrect NTP server(s). Set NTP server(s) to: $($NTP)." -ForegroundColor Green
        Log_ToSplunk -Message "ESXiHost $($ESXiHost) had incorrect NTP server(s). Set NTP server(s) to: $($configuredServers)." -Type "Log" -Status "Informational"
        }
    Else{
        Clear-Host
        Write-Host "$($esxihost) had the correct NTP server(s): $($configuredServers)." -ForegroundColor Green
        #Log_ToSplunk -Message "ESXiHost $($ESXiHost) had the correct NTP server(s) set: $($configuredServers)." -Type "Log" -Status "Informational"
    }
}

Function Set-ESXiSyslogServer($ESXiHost,$SysLogServer){
    $configuredServers = Get-VMHostSysLogServer -VMHost $ESXiHost

    if(!$configuredServers){
        Log_ToSplunk -Message "ESXiHost $($ESXiHost) did not have an NTP server. Added NTP server: $($configuredServers)." -Type "Log" -Status "Informational"
        }
    Else{
        #Log_ToSplunk -Message "ESXiHost $($ESXiHost) already had an NTP server set: $($configuredServers)." -Type "Log" -Status "Informational"
        }
}

Function Set-ESXiStartPolicy($ESXiHost){
    $StartPolicy = Get-VMHostStartPolicy -VMHost $ESXiHost
    If($StartPolicy.Enabled -ne $True){
        Write-Host "$($esxihost) StartPolicy has been Enabled." -ForegroundColor Green
        Set-VMHostStartPolicy -VMHostStartPolicy $StartPolicy -Enabled $True -StartDelay 120 -StopAction "GuestShutDown" -StopDelay 120 -WaitForHeartBeat $True -Confirm:$false
        Log_ToSplunk -Message "The StartPolicy of the VM ""$($VM.name)"" is now set to PowerOn" -Type "Log" -Status "Informational"
    }
    Else{
        Write-Host "$($esxihost) StartPolicy was already Enabled." -ForegroundColor Green
    }

    $VMs = Get-VMHost $ESXiHost | Get-VM | Get-VMStartPolicy
    ForEach($VM in $VMs){
        If($VM.StartAction -ne "PowerOn"){
            Set-VMStartPolicy -StartPolicy $VM -StartAction "PowerOn" -Confirm:$false
            Write-Host "The StartPolicy of the VM ""$($VM.name)"" is now set to PowerOn" -ForegroundColor Green
            Log_ToSplunk -Message "The StartPolicy of the VM ""$($VM.name)"" is now set to PowerOn" -Type "Log" -Status "Informational"
        }
        Else{
            Write-Host "The StartPolicy for VM ""$($VM.name)"" was already Enabled." -ForegroundColor Green
        }   
    }
}
# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"
Clear-Host
Write-Host "Connecting to vCenter: $($vCenter)" -ForegroundColor Yellow
Connect-VIServer $vCenter
$hosts = Get-VMHost

foreach ($Server in $hosts) {
    $esxihost = $Server.name
    If($Server.ConnectionState -eq "Connected"){
        Clear-Host
        Write-Host "Checking/Adding NTP Server to $($esxihost)." -ForegroundColor Yellow
        Start-Sleep 2
        Set-ESXiNTPServer $esxihost $ntpservers
        Start-Sleep 2
        Set-ESXiStartPolicy $esxihost
        }
    Else{
        Clear-Host
        Write-Host "$($ESXiHost) is not currently connected to vCenter." -ForegroundColor Red
        Start-Sleep 2
        Log_ToSplunk -Message "ESXi Host $esxihost was not connected to vCenter. Unable to make changes." -Type "Log" -Status "Informational"
    }
}
# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit