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
    Get-ADSIStoreComputerObjects.ps1

.SYNOPSIS
  Get-ADSIStoreComputerObjects.ps1

.DESCRIPTION

    
.EXAMPLE
 Get-ADSIStoreComputerObjects.ps1 -store [[string]<UFO_NUMBER>]

.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  6/10/2019
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Author:         user10 (6/10/2019)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Get-ADSIStoreComputerObjects.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

################[Initializations]################

$script:exitvalue = 0
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$Script:ProductName = "Get-ADSIStoreComputerObjects"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName)_$($store).txt"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
$ErrorActionPreference = "SilentlyContinue"
###################[Functions]###################
Function Append-Log($message)
{   
    $thetime = Get-Date -Format g
    "$thetime`: $message" | Out-File $Script:Logfile -Append
}#================[End Function]================
Function Return-Output($message)
{
    $thetime = Get-Date -Format g
    Write-Output "$thetime`: $message"
}#================[End Function ]================

Function Get-ADSIStoreComputerObjects($store,$ou)
{
    $objSearcher = New-Object DirectoryServices.DirectorySearcher
    $objSearcher.Filter = "(&(objectCategory=Computer)(|(Name=$store*s*)(Name=$store*j*)))"
    $objSearcher.SearchRoot = "LDAP://$OU"
    $objSearcher.PageSize = 1000
    $objComputer = $objSearcher.FindAll()
    foreach ($obj in $objComputer){
        $LDAPPath = [ADSI]$obj.path
        $computer = $LDAPPath.Name
        $online = (Test-NetConnection -ComputerName $computer).PingSucceeded
            if($online)
            {
                Write-Host "$computer is Online" -ForegroundColor Magenta
                $computers += $computer
            }
        
        }
        return $computers

}#================[End Function ]================

#################[Script Starts]#################
[string]$store = Read-Host "Enter UFO_NUMBER"
#[string]$store = $env:COMPUTERNAME.Substring(0,4)
$ou = "OU=Store Computers,DC=DOMAIN,DC=com"
$computers = Get-ADSIStoreComputerObjects -store $store -ou $ou
$computers | foreach {Get-WmiObject -Class win32_computersystem -ComputerName $_}

##################[Script Ends]##################