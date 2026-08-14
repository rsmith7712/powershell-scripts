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
    Set-ComputerOU.ps1

.SYNOPSIS
    Set-ComputerOU.ps1

.DESCRIPTION
    Set-ComputerOU.ps1
    
.EXAMPLE
    Set-ComputerOU.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  01/29/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Set-ComputerOU.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
<#
[cmdletbinding()]
param
(
    [string]$param1
    [string]$<ParamName> = $(throw "[ERROR] : -<ParamName> parameter is required.")
    [ValidateSet('item1','item2')]    
)
#>
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Set-ComputerOU"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){Remove-Item $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
###########################################[FUNCTIONS ]############################################
Function Log_ToSplunk
{
    Param
    (
        [parameter(Mandatory=$true,Position=0)][String]$Message,
        [parameter(Mandatory=$false,Position=1)][String]$Type = "Log",
        [parameter(Mandatory=$false,Position=2)][String]$Status = "Informational",    
        [parameter(Mandatory=$false,Position=3)][int]$ID = $Null
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
            uid = $script:uid
        }
    }
    $body = $body | ConvertTo-Json
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}#=========================================[End Function]==========================================
Function Append-Log
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$message
    )
    $thetime = Get-Date -Format g
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=========================================[End Function ]=========================================
Function Return.Output
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$message,
        [parameter(Mandatory=$false,Position=1)][string]$color="White"
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
}#=========================================[End Function ]=========================================
Function Process.Output($splunk = $false,$message,$type = "Log",$status = "Informational",$color = "White")
{
    If($splunk)
    {
        Log_ToSplunk -Message $message -Type $type -Status $status
    }
    Append-Log $message
    Return.Output -message $message -color $color
}#=========================================[END Function]==========================================
Function Set-ComputerOU($guid,$computer)
{
    $ou = "OU=Store Computers Windows 10,OU=Store Computers,DC=DOMAIN,DC=com"
    Process.Output -message "Moving computer object $($computer) [GUID:$($guid)] to $($ou)"
    $ErrorActionPreference = "Stop"
    Try
    {
        Move-ADObject $guid -TargetPath $($ou)
        $returncode = 0
        $status = "[SUCCESS] : Computer $($computer) [GUID:$($guid)] successfully moved to $($ou).";$color = "green"
    }
        Catch
        {
            $status = "[ERROR] : Issue encountered while moving Computer $($computer) [GUID:$($guid)] to $($ou). Exception: $($_.Exception.Message).";$color = "red"
            $returncode = 1
        }
    $ErrorActionPreference = "SilentlyContinue"
    Process.Output -message $status -color $color -splunk $true
    return $returncode
}#=========================================[End Function]==========================================

###########################################[SCRIPT STARTS ]########################################
Process.Output -message "Initiating $Script:ProductName script execution." -type "Begin" -status "Informational" -splunk $true -color "magenta"
$computers = Get-ADComputer -Filter "*" -SearchBase "OU=AutoPilot Domain Join,OU=Corporate Computers,DC=DOMAIN,DC=com" | Where-Object {[regex]$_.Name -match "[1-3,5,8,9]\d\d\dw[0,1][1-9]"}
#$computers = Get-ADComputer -Filter * -SearchBase "CN=Computers,DC=DOMAIN,DC=com" | Where-Object {$($_.Name) -match "[1-3,5,8]\d\d\dW[0,1][1-9]"}
$computersDiscovered = $computers.count
$computers | ForEach-Object{
    $computerGuid = $_.ObjectGuiD
    $computer = $_.Name
    $returncode = Set-ComputerOU -guid $computerGuid -computer $computer
}
Process.Output -message "Completing $Script:ProductName script execution. AD Computer Objects Discovered and processed: $($computersDiscovered)." -type "End" -status "Informational" -splunk $true -color "magenta"
EXIT $($returncode)
###########################################[SCRIPT END ]###########################################