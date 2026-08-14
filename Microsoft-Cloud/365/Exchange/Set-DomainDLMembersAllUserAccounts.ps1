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
    Set-DomainDLMembersAllUserAccounts.ps1

.DESCRIPTION
    Builds current distribution-list membership CSVs for all user accounts from field/region code lists, with a logging framework.

.FUNCTIONALITY
    Generates distribution-list membership for all user accounts.

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
if(!(Test-Path "$script:csvDir\new")){mkdir "$script:csvDir\new" -Force}
Remove-Item "$script:csvDir\new\*.*" -Force
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){Remove-Item $Script:Logfile -Force}
$ErrorActionPreference = "Continue"
if(!(Test-Path "$($script:script_Dir)\fieldDOMAINCodes.txt")){Append_Log -message "$fieldDOMAINCodes not found. Unable to continue." -passthru}
$fieldDOMAINCodes = Get-Content "$($script:script_dir)\fieldDOMAINCodes.txt"
if(!(Test-Path "$($script:script_dir)\fieldVVSCodes.txt")){Append_Log -message "$fieldVVSCodes not found. Unable to continue." -passthru}
$fieldVVSCodes = Get-Content "$($script:script_dir)\fieldVVSCodes.txt"
if(!(Test-Path "$($script:script_dir)\fieldNonStore.txt")){Append_Log -message "$fieldNonStore not found. Unable to continue." -passthru}
$fieldNonStore = Get-Content "$($script:script_dir)\fieldNonStore.txt"

Function Add-DlMembers($usrObj,$usrObjDl)
{
    $output = @()
    
    $csv = "$script:csvDir\new\$(($usrObjDl).Split("@")[0]).csv"
    $newObj = New-Object PSObject -Property ([Ordered]@{
        EmailAddress = $usrObj.mail
        samAccountName = $usrObj.samAccountName
        Department = $usrObj.Department
        Office = $usrObj.Office
        Title = $usrObj.Title
        Country = $usrObj.Country
        DistributionList = $usrObjDl
    })
    $newObj
    $output += $newObj
    $output | Export-Csv -Path $($csv) -NoTypeInformation -Append
}#==========================[End Function]==========================

## Store Managers ##
$storeManagersOU = "OU=Store Managers,OU=Store Accounts,DC=DOMAIN,DC=com"

$storeManagersUS = Get-ADUser -Filter "Enabled -eq '$true'" -SearchBase $storeManagersOU -Properties Country, Office, Department, Title, EmployeeID, Mail -ResultSetSize $null | 
Where-Object {($null -ne $_.mail) -and ($($_.UserPrincipalName).Substring(0,1) -eq "1") -and ($($_.UserPrincipalName).Substring(4,3) -eq "mgr")}

$storeManagersCA = Get-ADUser -Filter "Enabled -eq '$true'" -SearchBase $storeManagersOU -Properties Country, Office, Department, Title, EmployeeID, Mail -ResultSetSize $null | 
Where-Object {($null -ne $_.mail) -and ($($_.UserPrincipalName).Substring(0,1) -eq "2") -and ($($_.UserPrincipalName).Substring(4,3) -eq "mgr")}

# ----------------------------------------------------------------------------------------------
## Store Accounts ##
$storeAccountsOU = "OU=Store Users,OU=Store Accounts,DC=DOMAIN,DC=com"

$storeAccountsUS = Get-ADUser -Filter "Enabled -eq '$true'" -SearchBase $storeAccountsOU -Properties Country, Office, Department, Title, EmployeeID, Mail -ResultSetSize $null | 
Where-Object {($null -ne $_.mail) -and ($($_.UserPrincipalName).Substring(0,1) -match "1") -and ($($_.samAccountName).Substring(4,3) -match "str")}

$storeAccountsCA = Get-ADUser -Filter "Enabled -eq '$true'" -SearchBase $storeAccountsOU -Properties Country, Office, Department, Title, EmployeeID, Mail -ResultSetSize $null | 
Where-Object {($null -ne $_.mail) -and ($($_.UserPrincipalName).Substring(0,1) -match "2") -and ($($_.UserPrincipalName).Substring(4,3) -match "str")}

# ----------------------------------------------------------------------------------------------
## Full Time Employees ##
$adUsersFte = Get-ADUser -filter "enabled -eq '$true' -and ObjectClass -eq 'user'" -Properties Country, Office, Department, Title, EmployeeID, Mail -ResultSetSize $null | 
Where-Object{($null -ne $_.mail) -and ($null -ne $_.EmployeeId)}
# ----------------------------------------------------------------------------------------------
## Non-FTE's ##
$adUsersNonFte = @()
"OU=Remote Accounts,DC=DOMAIN,DC=com",
"OU=Corporate Accounts,DC=DOMAIN,DC=com",
"OU=Partner Accounts,DC=DOMAIN,DC=com",
"OU=External Accounts,OU=Domain Services,DC=DOMAIN,DC=com"|
ForEach-Object{
    $adUsersNonFte += Get-ADUser -filter "enabled -eq '$true' -and ObjectClass -eq 'user'" -SearchBase $_ -Properties Country, Office, Department, Title, EmployeeID, Mail -ResultSetSize $null | 
    Where-Object{($null -ne $_.mail) -and ($null -eq $_.EmployeeId)}
    }
# ----------------------------------------------------------------------------------------------
$total = ($storeManagersUS.Count + $storeManagersCA.Count + $storeAccountsUS.Count + $storeAccountsCA.Count + $adUsersFte.Count + $adUsersNonFte.Count)
Write-Host " Total = $($total)" -ForegroundColor Green

## AllCompanyEmployees@example.com ##
$all = @()
$all += $adUsersFte
$all += $adUsersNonFte
$all += $storeManagersUS
$all += $storeManagersCA
$all += $storeAccountsUS
$all += $storeAccountsCA

$usrObjDl = "AllCompanyEmployees@example.com"
$all | ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

### Stores ###
## AllStoreManagersUS@example.com ##
$usrObjDl = "AllStoreManagersUS@example.com"
$storeManagersUS | ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## AllStoreManagersCanada@example.com ##
$usrObjDl = "AllStoreManagersCanada@example.com"
$storeManagersCA | ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## AllStoresUS@example.com ##
$usrObjDl = "AllStoresUS@example.com"
$storeAccountsUS | ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## AllStoresCanada@example.com ## 
$usrObjDl = "AllStoresCanada@example.com"
$storeAccountsCA | ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

### Corporate ###
## AllCorporateFieldDOMAIN@example.com ##
$usrObjDl = "AllCorporateFieldDOMAIN@example.com"
$adUsersFte | Where-Object{($fieldDOMAINCodes -match $_.department) -and $_.Country -match "US"} | 
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## AllCorporateFieldVVS@example.com ##
$usrObjDl = "AllCorporateFieldVVS@example.com"
$adUsersFte | Where-Object{($fieldVVSCodes -match $_.department) -and $_.Country -match "CA"} | 
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## AllStoreSupportCenter-Fife@example.com ##
$usrObjDl = "AllStoreSupportCenter-Fife@example.com"
$adUsersFte | Where-Object {$_.Office -match "7000"} |
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## AllStoreSupportCenter@example.com ##
$usrObjDl = "AllStoreSupportCenter@example.com"
$adUsersFte | Where-Object {($_.Office -match "1000") -or ($_.Office -match "1001") -or ($_.Office -match "1002") -or ($_.Office -match "7000") -or ($_.Office -match "9000")} |
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## AllStoreSupportField2@example.com ##
$usrObjDl = "AllStoreSupportField2@example.com"
$adUsersFte | Where-Object{($fieldNonStore -match $_.department) -and $_.Country -match "US"} | 
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## DirectorTeam@example.com ##
$usrObjDl = "DirectorTeam@example.com"
$adUsersFte | Where-Object {$_.Title -match "Director"} | 
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## DMsDOMAIN@example.com ##
$usrObjDl = "DMsDOMAIN@example.com"
$adUsersFte | Where-Object {$_.Title -match "District Manager" -and $_.Country -match "US"} | 
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## DMsVVS@example.com ##
$usrObjDl = "DMsVVS@example.com"
$adUsersFte | Where-Object {$_.Title -match "District Manager" -and $_.Country -match "CA"} |
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## SRVSite2@domain ##
$usrObjDl = "SRVSite2@domain"
$adUsersFte | Where-Object {($_.Office -match "1000")} |
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## SRVSite1@example.com ##
$usrObjDl = "SRVSite1@domain"
$adUsersFte | Where-Object {$($_.Office) -match "1002"} | 
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## SRVSite3@example.com ##
$usrObjDl = "SRVSite3@domain"
$adUsersFte | Where-Object {$($_.Office) -match "1001"} | 
ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

## SRVPeopleManager@example.com ##
$usrObjDl = "SRVPeopleManager@example.com"
#$adUsersFte | Where-Object {$($_.Office) -match "1001"} | ForEach-Object{Add-DlMembers -usrObj $_ -usrObjDl $usrObjDl}

Write-Host " Store Accounts Canada : $($storeAccountsCA.Count)" -ForegroundColor Yellow
Write-Host " Store Managers Canada : $($storeManagersCA.Count)" -ForegroundColor Yellow
Write-Host " Store Accounts US : $($storeAccountsUS.Count)" -ForegroundColor Yellow
Write-Host " Store Managers US : $($storeManagersUS.Count)" -ForegroundColor Yellow
Write-Host " AD Users [FTE] : $($adUsersFte.Count)" -ForegroundColor Yellow
Write-Host " AD Users [Non - FTE] : $($adUsersNonFte.Count)" -ForegroundColor Yellow
Write-Host " Total Accounts = $($total)" -ForegroundColor Green
