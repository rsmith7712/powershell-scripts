# LEGAL
<# LICENSE
    MIT License, Copyright 2015 Richard Smith

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
    fLogical-FS_SPO_Script.ps1

.Pending
    - 
 .SYNOPSIS
    Copy-IncrementalSpoFs.ps1

.DESCRIPTION
    Copy-IncrementalSpoFs.ps1
    Read more: http://www.sharepointdiary.com/2015/01/run-powershell-script-as-administrator-automatically.html
    
.EXAMPLE
    Copy-IncrementalSpoFs.ps1
 
.NOTES
    Version:        v1.1
    Author:         user10
    Creation Date:  12/10/2019
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Copy-IncrementalSpoFs.ps1
        Read more: http://www.sharepointdiary.com/2015/01/run-powershell-script-as-administrator-automatically.html

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################

[cmdletbinding()]
param
(
    [string]$store = $(throw "[ERROR] : parameter is required: '$`store'")       
)

$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Copy-IncrementalSpoFs"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
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

$source = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution\"
