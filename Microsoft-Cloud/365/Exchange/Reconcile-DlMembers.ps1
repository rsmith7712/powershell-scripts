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
    Reconcile-DlMembers_2.ps1

.DESCRIPTION
    Compares previous and current distribution-list membership snapshots and reports the additions, removals and unchanged members, with a logging framework (variant).

.FUNCTIONALITY
    Reconciles distribution-list membership changes.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$script:ScriptName = "Reconcile-DomainDLMembers.ps1"
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Reconcile-DomainDLMembers"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$script:csvDir = "$($script:script_dir)\csv";if(!(Test-Path -Path $($script:csvDir))){mkdir $script:csvDir -Force}
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){Remove-Item $Script:Logfile -Force}
$ErrorActionPreference = "Continue"

Function Reconcile-DlMembers($dlName)
{
    $output = @()
    #$csv = $($dl).Split("@")[0]
    $csv = $($dlName)
    $membersNew = "$($script:csvDir)\new\$($csv).csv"
    $membersOld = "$($script:csvDir)\old\$($csv).csv"
    if ((Test-Path $($membersNew)) -and (Test-Path $($membersOld)))
    {
        $memberListNew = Import-Csv "$script:csvDir\new\$($csv).csv"
        $memberListOld = Import-Csv "$script:csvDir\old\$($csv).csv"
        $comparisonObj = Compare-Object -ReferenceObject $memberListOld -DifferenceObject $memberListNew -Property samAccountName #-IncludeEqual
#-----------------------------------------------------------------   
        $additions = 0
        $removals = 0
        $noChange = 0
        $all = 0
        $comparisonObj |
        ForEach-Object{
            $all++
            if($_.SideIndicator -eq "=>"){$action = "ADD";$additions++} 
            if($_.SideIndicator -eq "<="){$action = "REMOVE";$removals++}
            if($_.SideIndicator -eq "=="){$action = "NOCHANGE";$noChange++}
            $newObj = New-Object PSObject -Property ([Ordered]@{
                samAccountName = $($_.samAccountName)
                DistributionList = $($dlName)
                Action = $($action)
            })
            $($newObj)
            $output += $newObj
        }
        $output | Export-Csv -Path "$($script:csvDir)\DlMembershipChanges.csv" -NoTypeInformation -Append
        $totalChanges = ($additions-$removals)
        #-----------------------------------------------------------------    

        "-----------------------------------------------------------"
        "All Changes: $($all)"
        "Additions : $($additions)"
        "Removals : $($removals)"
        "No Change : $($noChange)"
        "Net Change : $($totalChanges)"
        "-----------------------------------------------------------"
        Write-Host ""
        Start-Sleep -Seconds 2
    }
}
if (Test-Path "$($script:csvDir)\DlMembershipChanges.csv"){Remove-Item "$($script:csvDir)\DlMembershipChanges.csv" -Force}
$dlName = " "
$dls = @()
$dls = "AllCorporateFieldDOMAIN@example.com",
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
    "SRVPeopleManager@example.com",
    "AllCompanyEmployees@example.com"
    $dls |
ForEach-Object{
    $dlName = (Get-ADGroup -filter "mail -eq '$($_)'").Name.Replace("*","").trim()
    Write-Host ""
    Write-Host $([string]$dlName) -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------"
    Reconcile-DlMembers -dlName $dlName
}
