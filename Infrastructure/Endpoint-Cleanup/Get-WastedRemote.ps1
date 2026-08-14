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
    Get-WastedRemote.ps1

.SYNOPSIS
    Get-WastedRemote.ps1

.DESCRIPTION
    Get-WastedRemote.ps1
    
.EXAMPLE
    Get-WastedRemote.ps1
    Get-WastedRemote.ps1 -Target <computername>
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  7/13/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Get-WastedRemote.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
#[cmdletbinding()]
param
(
    [string]$script:target = $env:COMPUTERNAME
)

$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Get-WastedRemote"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName)_$RemoteComputer.log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){Remove-Item $Script:Logfile}
#$ErrorActionPreference = "SilentlyContinue"
###########################################[FUNCTIONS ]############################################
Function Set-RunAsAdministrator()
{
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Write-host "Script is running with Administrator privileges!"
  }
  else
    {
        $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
        $ElevatedProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
        $ElevatedProcess.Verb = "runas"
        $ElevatedProcess.WindowStyle = "MINIMIZE"
       [System.Diagnostics.Process]::Start($ElevatedProcess)
       Exit
    }
}#=========================================[End Function]==========================================
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
Function Process-Output
{
    param
    (
        [parameter(Mandatory=$true)][string]$message,
        [parameter(Mandatory=$false)][string]$splunk = $false,
        [parameter(Mandatory=$false)][string]$splunkType,
        [parameter(Mandatory=$false)][string]$splunkStatus,
        [parameter(Mandatory=$false)][string]$color = "white"
    )
    If($splunkLog)
    {
        Log_ToSplunk -Message $message -Type $splunkType -Status $splunkStatus
    }
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=========================================[END Function]==========================================
Function Get-WastedRemote([string]$volparentdir,[string]$RemoteComputer)
{
    $allfilecount = 0
    $infectedallCount = 0
    $swofilecount = 0
    $swifilecount = 0

    Get-ChildItem "\\$RemoteComputer\$($volparentdir)$\" -Recurse -File -ErrorAction "continue" | 
    ForEach-Object{
        Try
        {
            if({$_.PsIsContainer})
            {
                $file = $_
                $allfilecount++
            }
            if([regex]$file.Extension -match "domainwasted$")
            {
                $swofilecount++
            }
            if([regex]$file.Extension -match "domainwasted_info")
            {
                $swifilecount++
            }  
        }
            Catch
            {
                [string]$ExceptionMessage = "[EXCEPTION] : $($_.Exception.Message)" 
                Write-Output $ExceptionMessage
            }
    }
    $ErrorActionPreference = "SilentlyContinue"
    $infectedallCount = ($swofilecount + $swifilecount)
    $infectedallPercentage = ‚Äú{0:P2}‚Äù -f ($infectedallCount/$allfilecount)
    return "$RemoteComputer,$volparentdir,$allfilecount,$swofilecount,$swifilecount,$infectedallcount,$infectedallPercentage"
}#=========================================[End Function]==========================================
#########################################[ SCRIPT STARTS ]#########################################
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
Clear-Host
Process-Output -message "Script Starting for $script:target" -splunk -status "Begin" -color "Green"
$script:csv = "$($script:script_dir)\logs\csv_$($env:COMPUTERNAME)"
if(!(Test-Path $csv)){mkdir $csv}
$outfile = "$($script:csv)\Get-WastedRemote_$script:target.csv"
if(Test-Path $outfile){Remove-Item $outfile}
"Computer.Name,Computer.Volume,FileCount.Total,DomainWasted.Total,DomainWasted_info.Total,InfectedFiles.Total,InfectedFiles.Percentage,Computer.OU"| Out-File $outfile -Encoding ascii -Append
$letters = @("c","d","e","f","g","h","I","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")

if(Test-Connection $script:target -Count 1 -Quiet)
{
    $letters | Foreach-Object {
        [string]$testvol = "$($_)"
        if(Test-Path "\\$script:target\$($testvol)$")
        {
            Write-Host "[STATUS] : Processing Volume: $($testvol)$ on $script:target, please wait for completion (CTRL+C to break)..." -ForegroundColor White -BackgroundColor Black
            $wastedRemote = Get-WastedRemote -volparentdir $testvol -RemoteComputer $script:target
            $wastedRemote | Out-File $outfile -Encoding ascii -Append
        }
    }
}
$message = ($outfile | Import-CSV | ConvertTo-Json)
$elapsed = [math]::Round($stopwatch.Elapsed.TotalMinutes,2)
$stopwatch.Stop()

Process-Output -message $message -splunk -color "Yellow"
Process-Output -message "[STATUS] : Script Completion.TTC = $($elapsed) Minutes." -splunk -status "End" -color "Green"
$global:processcount--
#invoke-item $outfile
EXIT
##########################################[ SCRIPT ENDS ]##########################################

