# LEGAL
<# LICENSE
    MIT License, Copyright 2019 Richard Smith

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
    Set-ComputerDistributionCenterLocalAdmins.ps1

.SYNOPSIS
  Set-LocalAdmininstrators.ps1

.DESCRIPTION
 Determines if specified security groups or users are members of the local administrators group on all the computers
 in the UFO_NUMBER specified.  The missing members are added if specified. This was initially developed as a tool to be used 
 with the  store computer file share migration/DartS migration taking place at all converted stores.
    
.EXAMPLE
 Set-LocalAdmininstrators.ps1 -store [[string]<UFO_NUMBER>]

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
    Determines if specified security groups or users are members of the local administrators group on all the computers
     in the UFO_NUMBER specified.  The missing members are added if specified. This was initially developed as a tool to be used
     with the  store computer file share migration/DartS migration taking place at all converted stores.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

######## Initializations ########
param(
    [string]$store = $(Read-Host "Enter UFO_NUMBER")
)
$script:exitvalue = 0
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$Script:ProductName = "Set-LocalAdmininstrators"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName)_$($store).txt"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
$ErrorActionPreference = "SilentlyContinue"
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force

########### Functions ###########
Function Append-Log($message)
{   
    $thetime = Get-Date -Format g
    "$thetime`: $message" | Out-File $Script:Logfile -Append
}#---------[END Function]---------
Function Return-Output($message)
{
    $thetime = Get-Date -Format g
    Write-Output "$thetime`: $message"
}#---------[END Function]---------
Function Get-LocalAdmin
{  
    param ($computer,$member)
    Try
    {
        $admins = Gwmi win32_groupuser ‚Äìcomputer $computer -ErrorAction Stop
        $admins = $admins |? {$_.groupcomponent ‚Äìlike '*"Administrators"'}
        $admins | ForEach-Object {  
            $_.partcomponent ‚Äìmatch ‚Äú.+Domain\=(.+)\,Name\=(.+)$‚Äù > $nul  
            $m = $matches[1].trim('"') + ‚Äú\‚Äù + $matches[2].trim('"')|findstr /I "$member"
            If ($m -eq $member)
            {
                $output = "SUCCESS: $($m) is a local Administrator on $computer."
            }
        }
    }
        Catch
        {
            $output = "ERROR: Unable to return local Administrators on $computer. Exception Message: $_.Exception.Message."
        }
    return $output
}#--------[END Function]--------
Function Add-LocalAdmin
{
    param ($Computer,$member,$Domain = "DOMAIN")
    Try
    {
        $localGroup = [adsi]"WinNT://$Computer/administrators,group"
        $domainGroup = [adsi]"WinNT://$Domain/$member,group"
        $localGroup.Add($domainGroup.path)
        $output = "SUCCESS: $($member) has been added to the local Administrators group on $computer."
    }
        Catch
        {
            $output = "ERROR: Unable to add $member to the local Administrators on $computer. Exception Message: $_."
        }
    return $output
}#--------[END Function]--------

######### Script Starts #########
Return-Output "Checking local administrator membership on affected computers."
Append-Log "Checking local administrator membership on affected computers."
    # -Properties OperatingSystemVersion | Where-Object {$_.OperatingSystemVersion -match "10.0"}
    $computers = Get-ADComputer -LDAPFilter "(name=$($store)*)" -SearchBase "OU=Distribution Center Computers,OU=Store Computers,DC=DOMAIN,DC=com"
    $computers | ForEach-Object{
        $computer = $_.name
        If((Test-NetConnection -ComputerName $computer).pingsucceeded)
        {
            Return-Output "SUCCESS: $computer is Online"
            Append-Log  "SUCCESS: $computer is Online"
            $Groups = @()
            $Groups = @("DESKTOP_CORP","DESKTOP_STORE","ORGADMINS")

            $Groups | ForEach-Object {
                $AdminMember = "DOMAIN\" + $_
                $member = $_
                $admintest = Get-Localadmin -computer $computer -member $AdminMember
                if ($admintest -ne $null)
                {
                    Return-Output $admintest
                    Append-Log $admintest
                }
                    else
                    {
                    Return-Output "WARNING: $AdminMember not a local Administrator on $computer. Attempting to add $AdminMember to local administrators group."
                    Append-Log "WARNING: $AdminMember not a local Administrator on $computer. Attempting to add $AdminMember to local administrators group."
                    $adminadd = Add-LocalAdmin -Computer $computer -member $member
                    Return-Output $adminadd
                    Append-Log $adminadd
                    }
                }
        }
            else
            {
                Return-Output "WARNING: $computer is offline"
                Append-Log "WARNING: $computer is offline"
            }   
}
########## Script Ends ##########
