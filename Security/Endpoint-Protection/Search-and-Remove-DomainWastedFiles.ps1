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
    Search-and-Remove-DomainWastedFiles.ps1

.SYNOPSIS
    Search-and-Remove-DomainWastedFiles.ps1

.DESCRIPTION
    Search target OU or domain and remove *.DomainWasted* files 
    
.EXAMPLE
    .\Search-and-Remove-DomainWastedFiles.ps1
 
.NOTES
    Version:        v1.0
    Author:         Richard Smith
    Creation Date:  2020-07-17
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Search target OU or domain and remove *.DomainWasted* files

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
$script:ScriptName = "Search-and-Remove-DomainWastedFiles"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Remove-DomainWastedFiles"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"

###########################################[FUNCTIONS ]############################################
## Function: Script needs to run as administrator - Set-RunAsAdministrator 
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
}
#=========================================[End Function]==========================================
## Function: Log results to Splunk 
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
}
#=========================================[End Function]==========================================
## Function: Process results output 
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
    If($splunk)
    {
        Log_ToSplunk -Message $message -Type $splunkType -Status $splunkStatus
    }
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}
#=========================================[END Function]==========================================
## Query user if they want User or Computer objects




#=========================================[END Function]==========================================
<# 
- Query AD for results; 
- Assign variables to each objects returned; 
- Build Switch statement;
- Allow selection of more than one OU for processing;
#>
#New-Object System.Management.Automation.Host.ChoiceDescription

$name = Read-host "Enter a name" 
$filter = "*$name*"
$list = get-ADOrganizationalUnit -Filter {name -like $filter} #Get a list of Active Directory Organization objects

Function menuFunction { #Create a menu function
  param ($list) 
  write-host
  write-host "************ MENU ************"
    $i = 1
    foreach ($item in $List){ # Create a dynamic menu item for each array object
        write-host "[$i] $($item.name)" -fore yellow
        $i++
    }
    write-host "[A] Remove Files with .DomainWasted* from Computer objects "..
    write-host "[N] Enter a new name"
    write-host "[Q] Quit"
    write-host
    $selection = read-host "Select a menu option"

    IF ($selection -match "^\d+$"){ #Check if selection is a number
        $choice = $($List[$selection - 1]) # Set $choice variable to the selected $list array object
    }else{ # If selection is not a number
        $choice = $selection
    }
    return $choice; #return selected array object or static menu selection
}
Do {
    $choice = menuFunction $list
    write-host
    switch ($choice) {
        {$list -contains $choice} { # Match if $list array contains the $selected $choice object
            write-host "You chose $($choice.name). Excellent choice." -fore green #Do stuff
        }
        q {exit}
        a {write-host "Removing files with *.DomainWasted* extension - Call Removal Function" -fore green
			## Call removal function ##
		  }
        n {
            $name = Read-host "Enter a name" 
            $filter = "*$name*"
            $list = Get-ADOrganizationalUnit -Filter {name -like $filter}     
          }
        default{write-host "Invalid menu choice" -fore red}  
    }
}until ($choice -eq "q")
#=========================================[END Function]==========================================
## Search remote machine and identify all DomainWasted files; Remove them with full path name
Function Remove-DomainWastedFiles{
	Get-ChildItem -Path \\SERVER\SHARE\* -Include *.domainwasted* -Recurse | 
ForEach-Object ($_) {Remove-Item $_.FullName -WhatIf}
}
#=========================================[END Function]==========================================
#########################################[ SCRIPT STARTS ]#########################################
## RunAsAdministrator
Set-RunAsAdministrator

## Query customer if they want User or Computer objects

 
## Query AD; Build Switch menu; Assign dynamic variables to results; Present actions against objects
menuFunction

## Execute action against selected objects
Remove-DomainWastedFiles

## Log results to Splunk
Process-Output

## Log results to a database





#########################################[ SCRIPT ENDS ]###########################################