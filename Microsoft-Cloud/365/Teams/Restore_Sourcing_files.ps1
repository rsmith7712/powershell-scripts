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
    Restore_Sourcing_files.ps1

.DESCRIPTION
    Loads the SharePoint Online client assemblies and restores sourcing files to a SharePoint library in batches.

.FUNCTIONALITY
    Restores files to SharePoint Online in batches.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Load SharePoint Online Assemblies
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

Function Split-Every($list, $count=20) {
    $aggregateList = @()

    $blocks = [Math]::Floor($list.Count / $count)
    $leftOver = $list.Count % $count
    for($i=0; $i -lt $blocks; $i++) {
        $end = $count * ($i + 1) - 1

        $aggregateList += @(,$list[$start..$end])
        $start = $end + 1
    }    
    if($leftOver -gt 0) {
        $aggregateList += @(,$list[$start..($end+$leftOver)])
    }

    return $aggregateList
}

##Variables for Processing
$SiteUrl = "https://domain.sharepoint.com/sites/domainnet/sourcing"
$UserName="engadmin2@example.com"

#Get the password to connect 
#$Password = Read-host -assecurestring "Enter Password for $UserName"
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName,$Password)

#Setup the context
$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
$Context.Credentials = $Credentials

#Get the web recycle bin
$site = $context.Site
$bin = $site.RecycleBin
$Context.Load($site)
$Context.Load($bin)
$Context.ExecuteQuery()

$DeletedFiles = $bin | Where-Object {($_.deletedbyemail -eq "muser24@example.com") -and ($_.dirname -eq "sites/domainnet/sourcing/lists/sourcing_trailer_archive")}
Write-Host "Total Number of Files that match filter:" $DeletedFiles.Count
#Restore from Recylce bin

$array = Split-Every $DeletedFiles

Write-host "There are $($array.Count) arrays to iterate through"

for ($i = 0; $i -lt $array.Count; $i++)
{
    Write-Progress -Activity "File Restore In Progress" -Status "Progress:" -PercentComplete ($i/$array.Count*100)
    foreach($item in $($array[$i])){ $item.Restore() }
    $context.ExecuteQuery()
    Write-Host "Array $i complete."
}