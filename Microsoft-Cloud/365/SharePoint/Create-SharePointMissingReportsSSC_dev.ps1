# LEGAL
<# LICENSE
    MIT License, Copyright 2015 Richard Smith

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
    Create-SharePointMissingReportsSSC_dev.ps1

.Pending
    - Prevent script from creating 'Are you missing a file - contact Ahlyshawndra Means' folders.
    - Set applicable SPO permissions
    - Copy files to the new SPO directories

.SYNOPSIS
    Get-SpoSscReports.ps1

.DESCRIPTION
    Get-SpoSscReports.ps1 Read more: http://www.sharepointdiary.com/2015/01/run-powershell-script-as-administrator-automatically.html
    
.EXAMPLE
    Get-SpoSscReports.ps1
 
.NOTES
    Version:        v1.1
    Author:         user10
    Creation Date:  12/2/2019
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Get-SpoSscReports.ps1 Read more: http://www.sharepointdiary.com/2015/01/run-powershell-script-as-administrator-automatically.html

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

######################################[INITIALIZATIONS]#######################################
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$Script:ProductName = "Create-SharePointFolder"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).txt"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
$Script:UID = [guid]::NewGuid()  
$ChangeDate = (Get-Date).AddDays(+1).ToString('MM/dd/yyyy')

$access = "Read" # "Full Control"
$datetime = (Get-Date).ToString('yyyyMMddHHmmss')
$folderName = "1019" # "NewFolder$datetime"
$useralias = "user2@example.com"
$LogDir = "C:\Logs"
$script:LogFile = "C:\temp\CreateSharePointFolders1.log"
$previousYear = (Get-Date -Format yyyy) - 1 
$currentYear = Get-Date -Format yyyy
$sourcePreviousYear = $source + $previousYear
$sourceCurrentYear = $source + $currentYear
#########################################[FUNCTIONS]##########################################
Function Get-FolderStructure($parent)
{
    Get-ChildItem $parent | Where-Object{ $_.PSIsContainer} |
     ForEach-Object {
                        [string]$fullpath = $_.FullName
                        $newfolder = $fullpath.Split("\")[-1]
                        return $newfolder
                    }
}#===================[End Function]===================
Function Set-SPOPSModule()
{
    $ErrorActionPreference = "Stop"
    Try
    {
        $moduleversion = (Import-Module "SharePointPnPPowerShellOnline" -PassThru -Force).Version
        $status = "[SUCCESS] : PS module 'SharePointPnPPowerShellOnline' version: $moduleversion imported successfully."
        $returncode = 0
    }
        Catch
        {
            $status = "[WARNING] : Failed to import PS module 'SharePointPnPPowerShellOnline.' Attemping to install module. The following exception occurred: $($_.Exception.Message).";$returncode = 1
            Try
            {
                Install-Module SharePointPnPPowerShellOnline -Force
                Import-Module "SharePointPnPPowerShellOnline" -PassThru -Force
                $status += "`n[SUCCESS] : PS module 'SharePointPnPPowerShellOnline' installed successfully.";$returncode = 0
            }
                Catch
                {
                    $status += "`n[ERROR] : Failed to install PS module 'SharePointPnPPowerShellOnline' after import attempt also failed. The following exception occurred: $($_.Exception.Message).";$returncode = 1
                }
        }
    $ErrorActionPreference = "SilentlyContinue"
    Write-Host $status -ForegroundColor White
    return $returncode
}#===================[End Function]===================
Function Set-SPOPnpConnection($u,$p,$url)
{
    Try
    {
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
        Try
        {
            Connect-PnPOnline -Url $spourl -Credentials $cred
            $status = "[SUCCESS] : Connection to '$spourl' succeeded.";$returncode = 0
        }
            Catch
            {
                $status = "[ERROR] : Connection failure for '$username' to '$spourl'. The following exception occurred: $($_.Exception.Message).";$returncode = 1
            }
    }
        Catch
        {
            $status = "[ERROR] : Authentication failure for $username. The following exception occurred: $($_.Exception.Message).";$returncode = 1
        }
    Finally
    {
           $ErrorActionPreference = "SilentlyContinue"
           Write-Host $status -ForegroundColor White
    }
    return $returncode
}#===================[End Function]===================
Function Migrate-FSFiles ($items)
{
 Foreach($item in $items) {
                            Write-Host $item                    
                            $spCheck = Get-PnPFile -url "$spListname\$spPath\$item"
                            $fsCheck = Get-ChildItem -Path "$fsPath\$item"
                                                        
                            $spModified = $spCheck.TimeLastModified
                            $fsModified = $fsCheck.LastWriteTime 
                            Write-Host "File Server Time Stamp: $fsModified"
                            Write-Host "Server File Time Stamp: $serverModified"
                                                    
                            if(($null -eq $spCheck) -or ($spModified -lt $fsModified))
                            {
                                Write-Host "$item does not exist or is outdated. Copy the latest from source."
                                $item = Add-PNPFile -Path "$fsPath\$item" -Folder "$spListname\$spPath\$item"
                            }
                          }
}#===================[End Function]===================
#######################################[SCRIPT STARTS]########################################
$username = "flowautomation@example.com"
$password = "<password>"
$dfsparentdir = "\\SERVER\SHARE\...\Field Leadership"
$spolistname = "CorporateReports"
$spoparentdir = $spolistname + "\Dropbox\Field Leadership"
$spourl = "https://domain.sharepoint.com/sites/TheA-Team" 
#PROD $spourl = "https://domain.sharepoint.com/sites/ReportCenter"
# Import 'SharePointPnPPowerShellOnline' PowerShell module *Required Module*
$modulestatus = Set-SPOPSModule
if($modulestatus -ne 0) {Exit 1}
# Connect to SharePoint Online
$connectionstatus = Set-SPOPnpConnection -u $username -p $password -url $spourl
#-----------[Create Top Level Directories]------------
If ($connectionstatus -eq 0)
{
    Try
    {
        Add-PnPFolder -Name "DropBox" -Folder $($spolistname)
        Add-PnPFolder -Name "Field Leadership" -Folder "$($spolistname)\DropBox"
    }
        Catch
        {
            $status = "[WARNING] : Exception Message: $($_.Exception.Message)."
        }
    #-----------------------------------------------------
    Get-ChildItem $dfsparentdir | Where-Object{$_.PSIsContainer} |
    ForEach-Object{
                    Add-PnPFolder -Name $($_.Name) -Folder $($spoparentdir)
                  }
    Get-ChildItem -Recurse $dfsparentdir | Where-Object{ $_.PSIsContainer} |
        ForEach-Object {
                        $newparentdir = $_.FullName
                        $spopath = $newparentdir.Replace($dfsparentdir,$spoparentdir)
                        Write-Host $spopath -BackgroundColor Blue
                        Get-FolderStructure -parent $newparentdir| 
                        ForEach-Object {
                                        $new = $_
                                        if(($new -notmatch "Are you missing a file") -and ($new -notmatch "If you are missing a file"))
                                        {
                                            Write-Host "Creating Folder '$spopath\$new'" -ForegroundColor Cyan
                                            # Write-Host "Creating Folder '$spopath\$_'" -ForegroundColor Cyan
                                            Add-PnPFolder -Name $($new) -Folder $($spopath) 
                                            #Start-Job -ScriptBlock{Add-PnPFolder -Name $using:new -Folder $using:spopath}
                                        }
                                       }
                        }
}
    Else
    {
        Exit 1
    }
#########################################[SCRIPT END]#########################################