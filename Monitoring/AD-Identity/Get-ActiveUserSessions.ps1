# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the ìSoftwareî),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED ìAS ISî, WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Get-ActiveUserSessions.ps1

.SYNOPSIS
    Get-ActiveUserSessions.ps1

.DESCRIPTION
    Get-ActiveUserSessions.ps1

.EXAMPLE
    Get-ActiveUserSessions.ps1

.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  07/8/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Get-ActiveUserSessions.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
<#
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
$Script:ProductName = "Get-ActiveUserSessions"
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
Function Return-Output
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
Function Process-Output($splunk = $false,$message,$type = "Log",$status = "Informational",$color = "White")
{
    If($splunk)
    {
        Log_ToSplunk -Message $message -Type $type -Status $status
    }
    Append-Log $message
    Return-Output -message $message -color $color
}#=========================================[END Function]==========================================
Function Get-LoggedOnUser($target,$outfile)
{
    $results = $null
    $results = @()
    $output = New-Object PSObject
    $output | Add-Member -MemberType NoteProperty -Name "TargetComputer" -Value $target
    #$user = Get-CimInstance ‚ÄìComputerName $target ‚ÄìClassName Win32_ComputerSystem | Select-Object UserName
    $output.UserName = (Get-WmiObject -Class win32_computersystem -ComputerName $target).UserName
    $results += $output
    $output | Format-List
    $results | Export-Csv -Path $outfile -NoTypeInformation -Append
}#=========================================[End Function]==========================================
Function Get-TSSessions {
    param(
        $ComputerName = "localhost",
        [string]$ip
    )
    $qwinsta = (qwinsta /server:$computerName | ForEach-Object{$_.trim() -replace ‚Äú\s+‚Äù,‚Äù,‚Äù} | ConvertFrom-Csv)
    $qwinsta | ForEach-Object {
        $output = $null
        $output = @{}
        $output = @{'ComputerName' = $ComputerName}
        $output.$IPv4 = $ip
        #$output | Add-Member -NotePropertyName "IPAddressV4" -NotePropertyValue $IPv4
        $session = $_.sessionName
        $user = $_.userName
        $state = $_.State
        $id = $_.id
        
        #Write-Host "IPAddressV4[$ipv4],ComputerName[$computerName],ID[$id],User[$user],Session[$session]State[$state]" -ForegroundColor White -BackgroundColor DarkBlue
        if (([regex]$user -match "^[0-9]*$") -and (!($state -match "Listen")))
        {
            if([regex]$session -match "rdp-tcp#")
            {
                $output.IPAddressV4 = $IPv4
                $output.ID = $id
                $output.Session = $session
                $output.State = $state 
                $output.User = $user
            }
            elseif ([regex]$session -notmatch "rdp-tcp#")
            {
                $output.ID = $user
                $output.Session = $session
                $output.State = $id
                $output.User = $session
            }
        }
            else 
            {
                $output.ID = $id
                $output.Session = $session
                $output.User = $user
                $output.State = $state
            }
        return [PSCustomObject]$output
    }
}#=========================================[End Function]==========================================
#==========================================[Script Starts]=========================================
$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
$output = "Script Starting: $Script:ProductName"
Process-Output -message $output -splunk $true

$outfile = "$($script:script_dir)\Get-ActiveSessions_testies123.csv"
if(Test-Path $outfile){Remove-Item $outfile}
$ous = @("OU=Domain Servers,DC=DOMAIN,DC=com",
"OU=Domain Controllers,DC=DOMAIN,DC=com",
"OU=SLC Servers,OU=Store Servers,DC=DOMAIN,DC=com",
"OU=Core Servers,OU=Store Servers,DC=DOMAIN,DC=com")
$ous |
ForEach-Object {
        $ou = $_
        $computeraccounts = Get-ADComputer -Filter "Name -like '*'" -SearchBase $ou
        ForEach($computer in $computeraccounts){
            $name = $computer.Name
            $test = (Test-Connection $name -Count 1)
            if($test)
            {
                [string]$ip = $test.Address
                Write-Host $ip -ForegroundColor cyan
                $sessions = Get-TSSessions -ComputerName $name -ip $($test.Address)
                $sessions
                $results += $sessions
            }
        }
}
$results | Export-Csv -Path $outfile -Append -NoTypeInformation
$stopWatch.Stop()
$timeRequired = $stopWatch.Elapsed.TotalSeconds
$output = "$Script:ProductName $script:uid completed. Time Elapsed: $timeRequired"
Process-Output -message $output -splunk $true
Invoke-item $outfile
#==========================================[Script Ends]===========================================