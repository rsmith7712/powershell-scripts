# LEGAL
<# LICENSE
    MIT License, Copyright 2019 Richard Smith

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
    store-startup.ps1

.SYNOPSIS
Store-Startup.ps1

.DESCRIPTION
Sets mapped network drives, bginfo, and Documents folder mapping

.EXAMPLE
 Store-Startup.ps1

.NOTES
Version:        1.1
Author:         user10
Creation Date:  12/19/2019
Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Sets mapped network drives, bginfo, and Documents folder mapping

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
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
$Script:ProductName = "store_startup.ps1"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).txt"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
###########################################[Functions]############################################
Function Launch-MessageBox($msg,$title,$options)
{ #Prompt the user with a box and return their response
    Add-Type -AssemblyName System.Windows.Forms
    $message = [System.Windows.Forms.MessageBox]::Show($msg,$title,$options)
    return $message
}#=========================================[End Function]==========================================
Function Set-MappedDrives($store)
{
    $reports = "\\" + $store + "CORE\Reports"
    & net use "R:" $reports /persistent:yes
}#=========================================[End Function]==========================================
Function Set-DocsPath ($store)
{
    $docspath = "\\" + $store + "CORE\Docs"
    [string]$regkey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
    $regvalue = "Personal"
    $regdata =  "$docspath"
    Set-ItemProperty -Path $regkey -Name $regvalue -Value $regdata
}#=========================================[End Function]==========================================
Function Set-BGInfo ($store)
{
    $bgi = 'default.bgi'
    $args = "C:\Software\BGInfo\$($bgi) /timer:0 /nolicprompt"
    If (Test-Path "C:\Software\BGInfo\$($bgi)")
    {
        Start-Process "C:\Software\BGInfo\Bginfo.exe" -ArgumentList $args
    }
        else
        {
            Exit 1   
        }
}#=========================================[End Function]==========================================

###########################################[SCRIPT STARTS]########################################
$store = $env:COMPUTERNAME.Substring(0,4)
if(!(test-path "\\SERVER\SHARE"))
{
    Launch-MessageBox -msg "This computer cannot connect to the Domain network.`n`nPlease verify that your network connection is not down due to scheduled maintenance.`n`nContact the Helpdesk at [PHONE] with any questions." -title "Your network connection is not available" 0
    Start-Sleep -seconds 10
    Exit 1
}
Set-BGInfo -store $store
Set-MappedDrives -store $store
Set-DocsPath -store $store
###########################################[SCRIPT END ]###########################################