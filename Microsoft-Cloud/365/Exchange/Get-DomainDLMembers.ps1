# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Get-DomainDLMembers.ps1

.DESCRIPTION
    For each named distribution list, exports the current recursive membership to CSV and removes those members (the snapshot/clear half of a DL reconciliation workflow), with a logging framework.

.FUNCTIONALITY
    Snapshots and clears distribution-list membership.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$script:ScriptName = "Set-DomainDLMembers.ps1"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Set-DomainDLMembers"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$script:csvDir = "$($script:script_dir)\csv";if(!(Test-Path -Path $($script:csvDir))){mkdir $script:csvDir -Force}
if(!(Test-Path "$script:csvDir\old")){mkdir "$script:csvDir\old" -Force}
Remove-Item "$script:csvDir\Old\*.*" -Force
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){Remove-Item $Script:Logfile -Force}
$ErrorActionPreference = "Continue"

Function Get-DlMemberList($dl,$dlName,$dlSamAccountName)
{
    $output = @()
    #$csv = "$script:csvDir\old\$(($dl).Split("@")[0]).csv"
    $csv = "$script:csvDir\old\$dlName.csv"
    Get-ADGroup -Filter "mail -eq '$($dl)'" |
    ForEach-Object{
        Get-ADGroupMember $($_) -Recursive |
        ForEach-Object{
            $newObj = New-Object PSObject -Property ([Ordered]@{
                Name = $_.Name
                samAccountName = $_.samAccountName
                DistributionList = "$($dl)"
            })
            $newObj
            $output += $newObj
            Get-ADUser -Identity $_.samAccountName | Remove-ADPrincipalGroupMembership -MemberOf $dlSamAccountName -Confirm: $false
        }
        $output | Export-Csv -Path $($csv) -NoTypeInformation
    }
}
#####################[Script Starts]#####################

$dls = @()
<## PRODUCTION ##
$dls = "AllCompanyEmployees@example.com",
    "AllCorporateFieldDOMAIN@example.com",
    "AllCorporateFieldVVS@example.com",
    "AllStoreManagersCanada@example.com",
    "AllStoreManagersUS@example.com",
    "AllStoresCanada@example.com",
    "AllStoreSupportCenter-Fife@example.com",
    "AllStoreSupportCenter@example.com",
    "AllStoreSupportField2@example.com",
    "AllStoresUS@example.com",
    "DirectorTeam@example.com",
    "DMsDOMAIN@example.com",
    "DMsVVS@example.com",
    "SRVSite2@example.com",
    "SRVSite1@example.com",
    "SRVSite3@example.com",
    "SRVPeopleManager@example.com"
#>
## TEST ##
$dls = 
"TestAllCompanyEmployees@example.com",
"TestAllStoreManagersCanada@example.com",
"TestAllStoreManagersUS@example.com",
"TestAllStoreSupportField@example.com"

$dls | 
ForEach-Object{
    $dl = $_
    $dlName = (Get-ADGroup -filter "mail -eq '$($_)'").Name.Replace("*","").trim()
    $dlSamAccountName =(Get-ADGroup -filter "mail -eq '$($_)'").samAccountName
    Get-DlMemberList -dl $dl -dlName $dlName -dlSamAccountName $dlSamAccountName
    (Get-ADGroup -Filter "mail -like '$($_)'"|Get-ADGroupMember).count
}
######################[Script Ends]######################