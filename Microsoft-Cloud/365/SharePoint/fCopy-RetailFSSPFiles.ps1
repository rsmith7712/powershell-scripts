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
    fCopy-RetailFSSPFiles_4.ps1

.DESCRIPTION
    Connects to SharePoint Online and copies current and prior-year retail report files to the Report Center site.

.FUNCTIONALITY
    Copies retail report files to SharePoint Online.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$currentyear = Get-Date -Format yyyy
$lastyear = $currentyear - 1
$twoyearsago = $currentyear - 2 
#$spourl = "https://domain.sharepoint.com/sites/TheA-Team"
$spourl = "https://domain.sharepoint.com/sites/ReportCenter"
$username = "flowautomation@example.com"
$password = "<password>"
$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)

            Try
            {
                $moduleversion = (Import-Module "SharePointPnPPowerShellOnline" -PassThru -Force).Version
                $status = "[SUCCESS] : PS module 'SharePointPnPPowerShellOnline' version: $moduleversion imported successfully.";$color = "green"
            }
                Catch
                {
                    $status = "[WARNING] : Failed to import PS module 'SharePointPnPPowerShellOnline.' Attemping to install module. The following exception occurred: $($_.Exception.Message).";$color = "yellow"
                }
            Finally
            {
                Write-Host $status -ForegroundColor $color
            }#-------------------------[END Try/Catch/Finally]-----------------------------------------
            Try
            {
                $spConnection = Connect-PnPOnline -Url $spourl -Credentials $cred
                $status = "[SUCCESS] : Connection to SharePoint Online Successfully established";$color = "green"
            }
                Catch
                {
                    $status = "[ERROR] : Failed to connect to $($spourl) as $($username). The following exception occurred: $($_.Exception.Message).";$color = "red"
                }
            Finally
            {
                Write-Host $status -ForegroundColor $color
            }#-------------------------[END Try/Catch/Finally]-----------------------------------------
$parent = "2019"
switch ($parent)
{
    dropbox     {$fsPath = "\Dropbox\Stores"}
    '2020'      {$fsPath = "\POS Initiatives\Reports for Store Distribution\" + [string]$currentyear}
    '2019'      {$fsPath = "\POS Initiatives\Reports for Store Distribution\" + [string]$lastyear}
    '2018'      {$fsPath = "\POS Initiatives\Reports for Store Distribution\" + [string]$twoyearsago}
    domain         {$fsPath = ""} # Placeholder
    vvs         {$fsPath = ""} # Placeholder
    sapl        {$fsPath = ""} # Placeholder
    Default     {$fsPath = "\POS Initiatives\Reports for Store Distribution\" + [string]$currentyear}
}
$dfsRootpath = "\\SERVER\SHARE\...\ALL"
$dfsParentdir = $dfsRootpath + $fspath
$files = Get-ChildItem $dfsparentdir -Recurse -File
$files | ForEach-Object{
    $file = $_ 
    $fsModified = $file.LastWriteTime
    $newParentdir = $file.DirectoryName
    $fileName = $file.Name
    $fsFile = $file.FullName
    [string]$UFO_NUMBER = $filename.Substring(0,4)
    if([regex]$UFO_NUMBER -match "^[1-3,5,8]\d\d\d$")
    {
        $spoListname = "StoreReports2"
        $spoParentdir = "$($UFO_NUMBER)\$($parent)"
        $spoPath1 = $newparentdir.Replace($dfsparentdir,$spoParentdir)
        $spoPath = $spoListname + "\" + $spoPath1
        $spFile = "$spopath\$file"
        $spModified = (Get-PnPFile -Url $spFile).TimeLastModified
        Write-Host "File Server File Time Stamp: $fsModified"
        Write-Host "SharePoint File Time Stamp: $spModified"
        if(($spFile -eq $null) -or ($spModified -lt $fsModified))
        {
            Write-Host "Copying newer version of '$file'" -ForegroundColor White -BackgroundColor Blue
            $ErrorActionPreference = "stop"
            Try
            {
                $scriptBlock = Add-PnPFile -Path $fsFile -Folder $spoPath -Connection $spConnection
                Start-Job -ScriptBlock{$using:scriptBlock}
                $status = "[SUCCESS] : PS Job started to copy $fileName to SharePoint.";$color = "green"
            }
                Catch
                {
                    $status = "[WARNING] : Unable to start PS Job to copy $fileName to SharePoint. The following exception occurred: $($_.Exception.Message).";$color = "yellow"
                }
                $ErrorActionPreference = "SilentlyContinue"
                Write-Host $status -ForegroundColor $color
        }
            else
            {
                Write-Host "Skipping '$file', already exists in SPO..." -ForegroundColor White -BackgroundColor Magenta
            }
    }
        else 
        {
            Write-Host "Not copying to SharePoint until a destination for non store folders is determined." -ForegroundColor White -BackgroundColor Magenta
        }
    $runningcount = (Get-Job | Where-Object{$_.State -eq "Running"}).count
    $suspendedcount = (Get-Job | Where-Object{$_.State -eq "Suspended"}).count
    Write-Host "Jobs Running: $($runningcount)`nJobs Suspended: $($suspendedcount)"
    Get-Job | Where-Object{$_.State -ne "Running"} | Receive-Job
    Get-Job | Where-Object{$_.State -eq "Running"} | Wait-Job | Receive-Job
}