# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
    Get-ADGroup-Members-from-Multiple-Domains-Throughout-the-Forest.ps1

.DESCRIPTION
    Pulls the members of groups named PCSupport or Domain Admins across all domains in the Active Directory forest.

.FUNCTIONALITY
    Reports group members across the AD forest.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#

Get-ADGroup-Members-from-Multiple-Domains-Throughout-the-Forest.ps1

Pull all the members of groups with "PCSupport" or "Domain Admins"
in the name of the group. We have multiple domains and I'm able to
use the "Get-ADForest" varaiable in another script to pull all
servers across the forest.



#>

$domains = (Get-ADForest).domains
$Members = foreach ($domain in $domains) {
    $Group = Get-ADGroup -Filter { Name -like "Enterprise Admins" } -Server $Domain 
    $Group | Get-ADGroupMember -Server $domain | Select @{Name="Domain";Expression={$Domain}},@{Name="Group";Expression={$Group.Name}},Name
}
     
$Members | Sort Domain,Group,Name | Out-GridView

#$Members | Sort Domain,Group,Name | Export-Csv "C:\temp\ADGroup-Members-from-Multiple-Domains-in-Forest.csv" -NoTypeInformation


