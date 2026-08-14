# LEGAL
<# LICENSE
    MIT License, Copyright 2021 Richard Smith

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
    fSet-ScoServiceAccount.ps1

.SYNOPSIS
    New-SCOAccount.ps1

.DESCRIPTION
    New-SCOAccount.ps1 is for use when creating a new Domain retail Self-CheckOut (SCO) service accounts.
    
.EXAMPLE
    New-SCOAccount.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  04/28/2021
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    New-SCOAccount.ps1 is for use when creating a new Domain retail Self-CheckOut (SCO) service accounts.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "New-DomainSvcAccount.ps1"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:xmlFolder = "$script:script_dir"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "Continue"
###########################################[FUNCTIONS ]############################################
Function Append-Log
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$message,
        [parameter(Mandatory=$false,Position=1)][string]$color = "White"
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=======================================[ End Function ]==========================================
Function Set-ServiceAccount
{
   param
    (
        [Parameter(Mandatory=$true)][string]$samaccountname,
        [Parameter(Mandatory=$true)][string]$scoComputer
    )
        $existing = Get-adUser -Identity $samaccountname
    if($($existing.samaccountname) -match $samaccountname)
    {
        Append-Log "$samaccountname already exists. Exiting..."
        return "$samaccountname already exists."
    }
    Try
    {
        Set-ADUser -Identity $samaccountname -Replace @{userWorkstations =$($scoComputer)}
        [string]$userworkstations = (Get-ADUser -Identity $samaccountname -Properties userWorkstations).userWorkstations
        if($($userworkstations) -match $($scoComputer))
        {
            Append-Log "[STATUS] : Successfully added $($scoComputer) to the 'userWorkstations' list attribute in AD for $($samaccountname)."
        }
            else
            {
                Append-Log "[ERROR] : FAILED to add $($scoComputer) to the 'userWorkstations' list attribute in AD for $($samaccountname)."
            }
    }
        Catch
        {
            Append-Log "[EXCEPTION] : The following exception occurred while attempting to create the new AD account: $($_.Exception.Message)."
        }
}#=======================================[ End Function ]==========================================
Set-ServiceAccount -samaccountname "1951RBT" -scoComputer "site"