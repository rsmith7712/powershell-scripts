b<#
.SYNOPSIS
 Set-DNSSearchServerRemoteWMI.ps1

.DESCRIPTION
 Reads a .csv file, then check status, and updates the DNS Search server settings on a list of remote hosts via WMI method.
 * Must place the .csv file in the same folder as this script.
 * Must be a local administrator on the remote computer in order for successful operation of script.
    
.EXAMPLE
  Set-DNSSearchServerRemoteWMI.ps1
 
.NOTES
  Version:        1.1
  Author:         user10
  Creation Date:  8/29/2019
  Purpose/Change: Initial Script Development

.HISTORY
#>

###############[ Initializations ]###############
[cmdletbinding()]
<#
param
(
    [ValidateSet('Store','ADQuery')]
    [string]$Target
)
#>
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$Script:ProductName = "Set_DNSSearchServerRemoteWMI"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).txt"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"

###############[ FUNCTIONS ]###############
Function Log_ToSplunk
{
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
}#==============[ END FUNCTION ]==============
Function Append-Log($message)
{   
    $thetime = Get-Date -Format g
    "$thetime`: $message" | Out-File $Script:Logfile -Append
}#==============[ END FUNCTION ]==============
Function Return-Output($message,$color="white")
{
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
}#==============[ END FUNCTION ]==============
Function Get-OnlineStatus($computer)
{
    $ErrorActionPreference = "Stop"
    Try
    {
        if((Test-Connection $computer -Count 1).StatusCode -eq 0)
        {
            [string]$status = "Online"
        }
            else
            {
                [string]$status = "Offline"
            }
    }
        catch
        {
            [string]$status = $false
        }
    Finally
    {
        $ErrorActionPreference = "Continue"
    }
    return $status
}#==============[ END FUNCTION ]==============
Function Set-DNSConfig($dns,$computer)
{
    $wmiquery = Get-WmiObject -class win32_NetworkAdapterConfiguration -ComputerName $computer
    $wmiquery | Where-Object {$null -ne $_.IPAddress}|
    ForEach-Object{
                    Try
                    {
                        $dnsold = $_.DNSServerSearchOrder
                        $adapter = $_.Description
                        $check = Get-WmiObject -class win32_NetworkAdapterConfiguration -ComputerName $computer -Filter "Description='$([string]$adapter)'"
                        if(!([string]$check.DNSServerSearchOrder -eq $dns))
                        {                        
                            $_.SetDNSServerSearchOrder($dns)
                            $check1 = Get-WmiObject -class win32_NetworkAdapterConfiguration -ComputerName $computer -Filter "Description='$([string]$adapter)'"
                            if([string]$check1.DNSServerSearchOrder -eq $dns)
                            {
                                $output = "DNS server search settings have been updated on host:$computer | adapter:$adapter.`n Old setting:{$dnsold}`n New setting:{$dns}"
                                Return-Output -message $output -color Green
                                $status = "Success"
                            }
                                else
                                {
                                    $output = "Failed to update DNS server search settings on host:$computer | adapter:$adapter.`n Old setting:{$dnsold}"
                                    Return-Output -message $output -color Red
                                    $status = "Fail"
                                }
                        }
                            else
                            {
                                $output = "DNS server search settings are already correct on host:$computer | adapter:$adapter. {$dns}"
                                Return-Output -message $output -color Cyan
                                $status = "Success"
                            }                        
                    }
                        Catch
                        {
                            $output = "Failed to update DNS server search settings on host:$computer | adapter:$adapter.`n Old setting:{$dnsold}`n Exception Message: $($_.Exception.Message)."
                            Return-Output -message $output -color Red
                            $status = "Fail"
                        }
                    Finally
                    {
                        Append-Log $output
                        Log_ToSplunk -Message $output -Status $status
                    }
                  }
}#==============[ END FUNCTION ]==============

###############[ SCRIPT START ]###############
# Test path to .csv file
$csv = ".\DNStest.csv"
if(Test-Path $csv)
{
    Return-Output -message "$csv found! Processing list..." -color White
    $servers = Import-Csv -Path $csv
}
    else
    {
        Return-Output -message "$csv NOT found. Please try again." -color Red
    }
# Process serverlist
$servers.hostname|ForEach-Object{
    [string]$computer = $_
    # Get Online Status
    if((Get-OnlineStatus -computer $computer) -eq "Online")
    {
        $output = "$computer`: Online. Continuing operation on this host..."
        Return-Output -message $output -color White
        Append-Log -message $output
        Log_ToSplunk -Message $output -Status "Success"
        if((Test-NetConnection -ComputerName $computer -port 135).TcpTestSucceeded -eq $true)
        {
            $output = "$computer`: Required TCP port 135 on $computer is listening. Continuing operation on this host..."
            Return-Output -message $output -color White
            Append-Log -message $output
            Log_ToSplunk -Message $output -Status "Success"
            Set-DNSConfig -computer $computer -dns "0.0.0.0","0.0.0.0"
        }
            else
            {
                $output = "$computer`:Required TCP port 135 on $computer is blocked. Unable to continue operation on this host."
                Return-Output -message $output -color Red
                Append-Log -message $output
                Log_ToSplunk -Message $output -Status "Fail"
            }
    }
        else
        {
            $output = "$computer`: Offline. Unable to continue operation on this host."
            Return-Output -message $output -color Red
            Append-Log -message $output
            Log_ToSplunk -Message $output
        }
}
################[ SCRIPT END ]################