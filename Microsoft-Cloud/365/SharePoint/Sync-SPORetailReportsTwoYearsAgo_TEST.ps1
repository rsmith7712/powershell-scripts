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
    Sync-SPORetailReportsTwoYearsAgo_TEST.ps1

.DESCRIPTION
    Connects to SharePoint Online and synchronizes the two-year-old retail report files to the Report Center site (test variant).

.FUNCTIONALITY
    Synchronizes two-year-old retail reports to SharePoint Online (test).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$currentyear = Get-Date -Format yyyy
$lastyear = $currentyear - 1
$twoyearsago = $currentyear - 2 
# $spourl = "https://domain.sharepoint.com/sites/TheA-Team"
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
                }#-------------------------[END Try/Catch]-----------------------------------------
            Finally
            {
                Write-Host $status -ForegroundColor $color
            }
            Try
            {
                $spConnection = Connect-PnPOnline -Url $spourl -Credentials $cred
                $status = "[SUCCESS] : Connection to SharePoint Online Successfully established";$color = "green"
            }
                Catch
                {
                    $status = "[ERROR] : Failed to connect to $($spourl) as $($username). The following exception occurred: $($_.Exception.Message).";$color = "red"
                }#-------------------------[END Try/Catch]-----------------------------------------
                Finally
                {
                    Write-Host $status -ForegroundColor $color
                }                
$dfsparentdir = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution\" + [string]$twoyearsago

$stores = @("1071","2012","2015","2026","2027","3011")
$files = Get-ChildItem $dfsparentdir -Recurse -File
$files | ForEach-Object{
    $file = $_    
    $newParentdir = $file.DirectoryName
    $fileName = $file.Name
    $fsFile = $file.FullName
    [string]$UFO_NUMBER = $filename.Substring(0,4)
    if(([regex]$UFO_NUMBER -match "^[1-3,5,8]\d\d\d$") -and ($stores -match $UFO_NUMBER))
    {
        $spoListname = "StoreReports3"
        $spoParentdir = "$($UFO_NUMBER)\$twoyearsago"
        $spoPath1 = $newparentdir.Replace($dfsparentdir,$spoParentdir)
        $spoSRP = $spoPath1.Replace("\","/")
        $spoPath = $spoListname + "\" + $spoPath1
        $spFile = "$spopath\$file"

        Write-Host $UFO_NUMBER -ForegroundColor Yellow
        Write-Host $fsFile -ForegroundColor Cyan
        Write-Host $spFile -ForegroundColor White
        Write-Host ""

        $ErrorActionPreference = "stop"
        Try
        {
            Write-Host $spoSRP -ForegroundColor Yellow
            $scriptBlock = Add-PnPFile -Path $fsFile -Folder $spoPath -Connection $spConnection
            Start-Job -ScriptBlock{$using:scriptBlock}
            #Start-Sleep -Seconds 1
            $status = "[SUCCESS] : PS Job started to copy $fileName to SharePoint.";$color = "green"
        }
            Catch
            {
                $status = "[WARNING] : Unable to start PS Job to copy $fileName to SharePoint. The following exception occurred: $($_.Exception.Message).";$color = "magenta"
            }
            $ErrorActionPreference = "SilentlyContinue"
        Write-Host $status -ForegroundColor $color
    }
        else 
        {
            Write-Host "Not copying to SharePoint until a destination for non store folders is determined." -ForegroundColor Magenta
        }
    $runningcount = (Get-Job | Where-Object{$_.State -eq "Running"}).count
    $suspendedcount = (Get-Job | Where-Object{$_.State -eq "Suspended"}).count
    Write-Host "Jobs Running: $($runningcount)`nJobs Suspended: $($suspendedcount)"
    Get-Job | Where-Object{$_.State -ne "Running"} | Receive-Job
    Get-Job | Where-Object{$_.State -eq "Running"} | Wait-Job | Receive-Job
}