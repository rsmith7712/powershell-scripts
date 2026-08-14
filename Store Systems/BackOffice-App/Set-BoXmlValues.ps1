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
    Set-BoXmlValues.ps1

.SYNOPSIS
    Set-BoXmlValues.ps1

.DESCRIPTION
    Set-BoXmlValues.ps1
    
.EXAMPLE
    Set-BoXmlValues.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  01/23/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Set-BoXmlValues.ps1

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
$Script:ProductName = "Set-BoXmlValues"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:xmlFolder = "$script:script_dir"
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
Function Get-StoreNum()
{
    $script:ipAddress = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'Description like "%I219-LM%"').ipaddress[0]    
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
Function Set-BoXmlValues($lane,$xmlFolder)
{
    [string]$storeid = $($env:COMPUTERNAME).Substring(0,4)
    # Get SLC
    if (Test-Connection -Count 1 $($storeid + "slc1") -Quiet)
    {
        [string]$slc = $($storeid + "slc1")
    }
    elseif (Test-Connection -Count 1 $($storeid + "slc2") -Quiet)
    {
        [string]$slc = $($storeid + "slc2")
    }
        else
        {
            $status = "SLC server unavailable via the network for store $($storeid). Entering default value of $($storeid + "slc1")."
            Process-Output -message $status -color "magenta"
            [string]$slc = $($storeid + "slc1")
        }
    $primaryserver = $slc
    $databaseserver = $slc

    # Get environment
        if ($($storeid.substring(0,1)) -eq "9")
        {
            $environment = "test"
        }
            else {$environment = "prod"}
    switch ($environment)
    #[if 2nd digit of the store ID = 9 then lbstorecentertest else lbstorecenter]
    {
        "test"{$scserver = "lbstorecentertest.example.com"}
        "prod"{$scserver = "lbstorecenter.example.com"}
    }
    # Set country
    $country = $storeid.substring(0,1)
    switch ($country)
        #[0 for US/CA; 1 for AU]
    {
        "1" { # US
                $UseVAT = "0"
                $language = "en_us"
            }
        "2" { # CA
                $UseVAT = "0"
                $language = "en_ca"
                <#
                $l = Read-Host "Canadian Store: Enter E for (E)nglish, F for (F)rench"
                switch ($l)
                {
                    "E"{$language = "en_ca"}
                    "F"{$language = "fr_ca"}
                    default{$language = "en_ca"}
                }
                #>
            }
        "3" { # AU
                $UseVAT = "1"
                $language = "en_au"
            }
        default{$UseVAT = "0"}
    }
    #Set language
    switch ($language)
        #[EN-US/CA = 1033; FR-CA = 3084; EN-AU = 3081]
    {
        "en_au" {
                    $InstallLanguages = "3081"
                    $StoreLanguage = "3081"
                }
        "en_ca" {
                    $InstallLanguages = "1033"
                    $StoreLanguage = "1033"
                }
        "fr_ca" {
                    $InstallLanguages = "3084"
                    $StoreLanguage = "3084"
                }
        "en_us" {
                    $InstallLanguages = "1033"
                    $StoreLanguage = "1033"
                }
        default {
                    $InstallLanguages = "1033"
                    $StoreLanguage = "1033"
                }
    }
    $xmlTemplate = "$($xmlFolder)\xmlinput_template.xml"
    $xmlFileName = "$($xmlFolder)\xmlinput_domain.xml"
    [xml]$xmlDoc = New-Object system.Xml.XmlDocument
    [xml]$xmlDoc = Get-Content $xmlTemplate

    $xmlDoc.parameters.primaryserver.value = $primaryserver
    $xmlDoc.parameters.databaseserver.value = $databaseserver
    $xmlDoc.parameters.termno.value = $lane
    $xmlDoc.parameters.storeid.value = $storeid
    $xmlDoc.parameters.scserver.value = $scserver
    $xmlDoc.parameters.UseVAT.value = $UseVAT
    $xmlDoc.parameters.InstallLanguages.value = $InstallLanguages 
    $xmlDoc.parameters.StoreLanguage.value = $StoreLanguage

    $xmlDoc.Save($xmlFileName)
    $status = "[STATUS] : SUCCESS = $($?). "
    Process-Output -message $status -color "White"
}#===================[End Function]===================

#$lane = ""
Set-BoXmlValues -lane $lane -xmlFolder $xmlFolder