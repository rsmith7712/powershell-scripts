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
    Update-DomainDLMembership.ps1

.DESCRIPTION
    Applies distribution-list membership updates from the generated membership snapshots, with a logging framework (the apply half of the DL reconciliation workflow).

.FUNCTIONALITY
    Applies distribution-list membership updates.

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
Function Add-DLMembers($csvFiles)
{
    Foreach($csvFile in $csvFiles)
    {
        $csvObj = Import-Csv -Path $($csvFile.FullName)
        $csvObj | 
        ForEach-Object{
            $group = $_.DistributionList
            $account = $_.samaccountname
            $ErrorActionPreference = "Stop"
            Try
            { 
                "$group $account"
                Get-ADGroup -Filter "mail -like '$($group)'" |
                Add-ADGroupMember -Members $account -PassThru
            }
                Catch
                {
                    "The following exception occurred: $($_.Exception.Message)."
                }
            Finally
            {
                $ErrorActionPreference = "SilentlyContinue"
            }
        }
    }
}#=======================================[ End Function ]==========================================
Function Get-DlMemberList($dl,$dlName,$dlSamAccountName)
{
    $output = @()
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
}#=======================================[ End Function ]==========================================

#####################[Script Starts]#####################

$csvFiles = Get-ChildItem "$($script:script_dir)\csv\new"
$csvFiles | 
ForEach-Object{
    $dl = (Get-ADGroup "_$($_.basename)" -Properties mail).mail
    $dlName = (Get-ADGroup -filter "mail -eq '$($dl)'").Name.Replace("*","").trim()
    $dlSamAccountName =(Get-ADGroup -filter "mail -eq '$($dl)'").samAccountName
    #Get-DlMemberList -dl $dl -dlName $dlName -dlSamAccountName $dlSamAccountName
    (Get-ADGroup -Filter "mail -like '$($_)'"| Get-ADGroupMember).count
}
#----------------------------------------------------
Add-DlMembers -csvFiles $csvFiles


######################[Script Ends]######################