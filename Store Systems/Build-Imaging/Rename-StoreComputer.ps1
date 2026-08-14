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
    Rename-StoreComputer.ps1

.SYNOPSIS
    Rename-StoreComputer.ps1

.DESCRIPTION
    Rename-StoreComputer.ps1
    
.EXAMPLE
    Rename-StoreComputer.ps1
 
.NOTES
    Version:        v1.1
    Author:         user10
    Creation Date:  02/04/2020
    Purpose/Change: 
                    - Added domain\slcmgr credentials because of Access Denied issues
                    - Added error handling for the ip address/UFO_NUMBER format, new hostname format (regex)

.HISTORY
    Version:        v1.0
    Author:         user10
    Creation Date:  01/23/2020
    Purpose/Change: Initial script creation

.FUNCTIONALITY
    Rename-StoreComputer.ps1

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
$Script:ProductName = "Rename-StoreComputer"
$Script:Logfile = "C:\temp\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
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
Function Get-StoreNum($script:ipAddress)
{
    $script:ipParsed = $script:ipAddress.split(".")
    $ipParsed = $script:ipParsed
    $thirdOct = $ipParsed[2]
    $secondLength = $ipParsed[1].length
    $thirdLength = $ipParsed[2].length
    Switch($secondLength){
        2{ # Two Digits in 2nd Octet
            Switch($thirdLength){ # "New" IP Scheme
                1{#Adds a 0 for stores with a single digit 3rd octet like 1003
                    $UFO_NUMBER = $ipParsed[1]+"0"+$ipParsed[2]
                    $script:ipScheme = "2"
                    Return $UFO_NUMBER
                    }
                2{
                    $UFO_NUMBER = $ipParsed[1]+$ipParsed[2]
                    $script:ipScheme = "2"
                    Return $UFO_NUMBER
                    }
                3{# Offsite Production(Except 2001) will have a .1xx 3rd octet. ie, 2149A will be 10.21.149.xxx
                    $subSite = $ipParsed[2].substring(1,2)
                    $UFO_NUMBER = $ipParsed[1]+$subSite
                    $script:ipScheme = "3"
                    Return $UFO_NUMBER
                    }
                }
            }
        3{ # Three Digits in 2nd Octet
            Switch($ipParsed[1]){ #Gets the prefix of the store based on the 2nd octet. "Old" IP Scheme
                "200"{$prefix = 2} #Canada
                "202"{$prefix = 1} #US VV and Domain
                "204"{$prefix = 3} #Australia
                "208"{$prefix = 5} #US Domain
                "210"{$prefix = 8} #US Partner3
                "151"{$prefix = 9} #Corporate (for development purposes only.)
                "100"{return "2001"} #CA 2001 WAREHOUSE
                "168"{return "9101"} #Test
                "209"{
                    Switch($ipParsed[2]){
                        "50"{$labStore = "1950"}
                        "51"{$labStore = "1951"}
                        "55"{$labStore = "2955"}
                        "56"{$labStore = "1956"}
                        "59"{$labStore = "1959"}
                        "100"{$labStore = "2950"}
                        "101"{$labStore = "2951"}
                        "102"{$labStore = "2952"}
                        "109"{$labStore = "2959"}
                        "250"{$labStore = "3950"}
                        }
                    Return $labStore
                    }
                }
            Switch($thirdLength){ #Gets the rest of the UFO_NUMBER based on 3rd octet
                1{$suffix = "00$thirdOct"}
                2{$suffix = "0$thirdOct"}
                3{$suffix = "$thirdOct"}
                }
            $UFO_NUMBER = "$prefix"+"$suffix" #Combines to create UFO_NUMBER
            Write-Host $UFO_NUMBER -ForegroundColor Cyan
            return $UFO_NUMBER
            }
        }
}#=========================================[End Function]==========================================
Function Get-Computers($storeNum)
{
    $num = 0
    do
    {
        $num++
        [string]$newName = "$storeNum`W0$num"
        Process-Output -message "[STATUS] : Checking the online status for Hostname: '$newName'."
        $test = Test-Connection -Count 2 $newName -Quiet
        if (!($test))
        {
            Process-Output -message "[SUCCESS] : New hostname: '$newName' will be used as the new computer hostname." -ForegroundColor Green
            return $newName
        }
            Else
            {
                Process-Output -message "[WARNING] : $newName is already in use. Checking the next incremental value." -ForegroundColor Yellow
            }
    }
    until($num -gt 11)
    if ($num -gt 11){$newName = 0}
    return [string]$newName
}#=========================================[End Function]==========================================
Function Change-ComputerName($newName)
{
    $domainUser = "example.com\slcadmin"
    $domainPass = ConvertTo-SecureString "<password>" -AsPlainText -Force
    $domainCred = New-Object System.Management.Automation.PSCredential $domainUser, $domainPass
    Try
    {
        #$ErrorActionPreference = "Stop"
        $currentMachine = Get-WmiObject Win32_ComputerSystem -Credential $domainCred
        if ($currentMachine.PartOfDomain)
        {
            $returncode = ($currentMachine.Rename($newName)).ReturnValue
            if($returncode -eq 0)
            {
                $status = "[SUCCESS] : Computer successfully renamed to $($newName). A restart is required to complete the operation."
            }
                else 
                {
                    $status = "[ERROR] : Issue encountered while renaming the local computer. Exit code: $($returncode)."
                }
        }
    }
        Catch 
        {
            $status = "[ERROR] : Issue encountered while renaming the local computer. Exception: $($_.Exception.Message)."
        }
    #$ErrorActionPreference = "SilentlyContinue"
    Process-Output -message $status -color White
    return $returncode
<#
 Common returncode values for the 'Rename' method:
    0 - Success
    5 - Access denied
    87 - Invalid parameter
    1326 - Logon Failure
    2697 - Computer account could not be found
#>
}#=========================================[End Function]==========================================

###########################################[SCRIPT STARTS ]########################################
Set-RunAsAdministrator
#$script:ipAddress = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'Description like "%I219-LM%"').ipaddress[0]
$script:ipAddress = (Get-WmiObject -class win32_NetworkAdapterConfiguration | Where-Object {$_.DNSDomain -eq "example.com"}).ipaddress[0]
$storeNum = Get-StoreNum -ip $script:ipAddress
if ([regex]$storeNum -notmatch "^[1-3,5,8]\d\d\d$")
{
    Process-Output -message "[STATUS] : Error: Something when wrong. UFO_NUMBER: '$($storeNum)' does NOT match the correct format. Exiting script." -splunk $true
    Start-Sleep -Seconds 05
    Exit 1
}
Process-Output -message "[STATUS] : UFO_NUMBER: '$($storeNum)'" -color "White"
$newName = Get-Computers -storeNum $storeNum
if ([regex]$newName -match "[1-3,5,8]\d\d\dW[0,1][1-9]")
{
    Process-Output -message "[STATUS] : Proposed new hostname: '$($newName)'."
    $status = Change-ComputerName -newName $newName
}
    else 
    {
        Process-Output -message "[STATUS] : Error: Something when wrong. The proposed Hostname: '$($newName)' does NOT match the correct format. Exiting script." -splunk $true
        Start-Sleep -Seconds 05
        Exit 1
    }
Process-Output -message "[STATUS] : Computer rename process completed with the following Exit code: '$($status)'." -color "White" -splunk $true
Exit $status

<# *** OLD CODE: Test this script, then delete. ***
====================================================
$storeNum = Get-StoreNum
Process-Output -message "[STATUS] : Identified UFO_NUMBER as : '$($storeNum)'."
$newName = Get-Computers -storeNum $storeNum
Process-Output -message "[STATUS] : Identified new hostname as: '$($newName)'."
$status = Change-ComputerName -newName $newName
Process-Output -message "[STATUS] : Computer rename process completed with the following Exit code: '$($status)'." -color "White"
Exit $($status)
====================================================
#>
###########################################[SCRIPT END ]###########################################