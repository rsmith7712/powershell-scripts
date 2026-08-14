# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Richard Smith

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
    Sync-SPORetailReports_5.ps1

.SYNOPSIS
    Sync-SPORetailReports.ps1

.DESCRIPTION
    Sync-SPORetailReports.ps1 is designed to run as a scheduled server task. It is used to provide a differential 
    synchronization of retail store reports between the file servers and SharePoint Online.
    
    Source of files:

    Destination of files:
    
.EXAMPLE
    Sync-SPORetailReports.ps1
 
.NOTES
    Version:        v1.1
    Author:         user10
    Creation Date:  03/18/2020
    Purpose/Change: Added some major efficiencies, reconfigured to write to production ReportCenter StoreReports doclib.

.HISTORY
    Version:        v1.0
    Author:         user10
    Creation Date:  03/06/2020
    Purpose/Change: Initial script creation

.FUNCTIONALITY
    Sync-SPORetailReports.ps1 is designed to run as a scheduled server task. It is used to provide a differential
        synchronization of retail store reports between the file servers and SharePoint Online.

        Source of files:

        Destination of files:

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Sync-SPORetailReports"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:xmlFolder = "$script:script_dir"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
###########################################[FUNCTIONS ]############################################
Function Set-RunAsAdministrator()
{
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Write-host "Script is running with Administrator privileges!"
  }
  else
    {
        $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
        $ElevatedProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
        $ElevatedProcess.Verb = "runas"
        $ElevatedProcess.WindowStyle = "MINIMIZE"
       [System.Diagnostics.Process]::Start($ElevatedProcess)
       Exit
    }
}#=========================================[End Function]==========================================
Function Log_ToSplunk
{
    Param
    (
        [parameter(Mandatory=$true,Position=0)][String]$Message,
        [parameter(Mandatory=$false,Position=1)][String]$Type = "Log",
        [parameter(Mandatory=$false,Position=2)][String]$Status = "Informational",    
        [parameter(Mandatory=$false,Position=3)][int]$ID = $Null
    )    
    $product = "team_" + $Script:ProductName
    $uri = "https://hecext.example.com:18443/services/collector/event"
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.add('Authorization', 'Splunk Application-Key-Here')
    $body = @{
        sourcetype = 'domain:ps:log'
        host = $env:COMPUTERNAME
        event = @{
            message = $Message
            user = $env:USERNAME
            product = $Product
            type = $Type
            status = $Status
            id = $ID
            uid = $script:uid
        }
    }
    $body = $body | ConvertTo-Json
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}#=========================================[End Function]==========================================
Function Process-Output
{
    param
    (
        [parameter(Mandatory=$true)][string]$message,
        [parameter(Mandatory=$false)][string]$splunkLog = $false,
        [parameter(Mandatory=$false)][string]$splunkType,
        [parameter(Mandatory=$false)][string]$splunkStatus,
        [parameter(Mandatory=$false)][string]$color = "white"
    )
    If($splunkLog)
    {
        Log_ToSplunk -Message $message -Type $splunkType -Status $splunkStatus
    }
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=========================================[END Function]==========================================
Function Set-SpoPnpFolderPermission ($foldername,$spoListname)
{
    $listItem = Get-PnPListItem -List $spoListName -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$foldername</Value></Eq></Where></Query></View>"
    if($listItem)
    {
        Set-PnPListItemPermission -List $spoListName -Identity $listItem -User "$folderName`str@example.com" -AddRole "Read" -ClearExisting
        Set-PnPListItemPermission -List $spoListName -Identity $listItem -User "$folderName`mgr@example.com" -AddRole "Read"
        Set-PnPListItemPermission -List $spoListName -Identity $listItem -User "flowautomation@example.com" -RemoveRole "Full Control" 
    }
        else
        {
            Process-Output "[STATUS] : Unable to locate '$folderName' in the DocLib: $listname" -color "Red" -splunkLog $true -splunkType "Log" -splunkStatus "Failure"
        }
}#=========================================[End Function ]=========================================
Function Connect-SPOnline()
{
    # $script:spourl = "https://domain.sharepoint.com/sites/TheA-Team"
    $script:spourl = "https://domain.sharepoint.com/sites/ReportCenter"
    $username = "flowautomation@example.com"
    $password = "<password>"
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
    Try
    {
        $moduleversion = (Import-Module "SharePointPnPPowerShellOnline" -PassThru -Force).Version
        $status = "[SUCCESS] : PS module 'SharePointPnPPowerShellOnline' version: $moduleversion imported successfully.";$color = "green";$splunkStatus = "Success"
    }
        Catch
        {
            $status = "[WARNING] : Failed to import PS module 'SharePointPnPPowerShellOnline.' Attemping to install module. The following exception occurred: $($_.Exception.Message).";$color = "yellow"
        }
    Finally
    {
        Process-Output -message $status -color $color -splunkLog $true -splunkType "Log" -splunkStatus $splunkStatus
    }
    Try
    {
        $spConnection = Connect-PnPOnline -Url $spourl -Credentials $cred
        $status = "[SUCCESS] : Connection to SharePoint Online Successfully established";$color = "green";$splunkStatus = "Success"
    }
        Catch
        {
            $status = "[ERROR] : Failed to connect to $($spourl) as $($username). The following exception occurred: $($_.Exception.Message).";$color = "red";$splunkStatus = "Failure"
        }
        Finally
        {
            Process-Output -message $status -color $color -splunkLog $true -splunkType "Log" -splunkStatus $splunkStatus
        }
}#=========================================[End Function ]=========================================
Function Sync-RetailReports($fileName,$fsFile,$dfsparentdir,$newParentdir,$spoParentdir,$spoListName,$UFO_NUMBER,$rootLabel)
{
    if ($rootLabel -eq "PnL")
        {
            $spoPath = "$($spoListname)\$($newparentdir.Replace($dfsparentdir,$spoParentdir))\PnL"
        }
            else
            {
                $spoPath = "$($spoListname)\$($newparentdir.Replace($dfsparentdir,$spoParentdir))"
            }
        $spFile = "$spopath\$fileName"
        $fsModified = (Get-Item -path $fsFile).LastWriteTime
        $spCreated = (Get-PnPFile -Url $spFile).TimeCreated
        Write-Host "Store: $UFO_NUMBER" -ForegroundColor Yellow
        Write-Host "File Server File Time Stamp: $fsModified"
        Write-Host "SharePoint File Time Stamp: $spCreated"
        if(($null -eq $spFile) -or ($spCreated -lt $fsModified))
        {
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
            Process-Output -message $status -color $color
        }
            else
            {
                Write-Host "Skipping $fsFile. Does not meet specified attribute parameters."  -ForegroundColor Gray
            }
        $runningcount = (Get-Job | Where-Object{$_.State -eq "Running"}).count
        $suspendedcount = (Get-Job | Where-Object{$_.State -eq "Suspended"}).count
        Write-Host "[JOB STATUS] : Jobs Running: $($runningcount)`nJobs Suspended: $($suspendedcount)"
        Get-Job | Where-Object{$_.State -ne "Running"} | Receive-Job
        Get-Job | Where-Object{$_.State -eq "Running"} | Wait-Job | Receive-Job
}#=========================================[End Function ]=========================================
###########################################[SCRIPT STARTS ]########################################
Process-Output -message "Initiating $Script:ProductName script execution." -type "Begin" -status "Informational" -splunk $true -color "Magenta"
[string]$currentyear = Get-Date -Format yyyy
$timeSpan = (Get-Date).AddDays(-80)
[string]$spoListName = "StoreReports"
Connect-SPOnline
$stores = @()
# TEST # $stores = @("1071","2015","2027","3011")
Get-ADUser -filter '*' -searchbase "OU=Store Managers,OU=Store Accounts,DC=DOMAIN,DC=com" |
ForEach-Object {$stores += [string]($($_.SamAccountName.Substring(0,4)))}
$rootLabel = "CY"
$dfsparentdir = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution\$($currentyear)"
$files = Get-ChildItem $dfsparentdir -Recurse -File | Where-Object{$stores -match $($_.Name).Substring(0,4)}
$files | 
ForEach-Object{
    $file = $_
    $newParentdir = $file.DirectoryName
    $fileName = $file.Name
    $fsFile = $file.FullName
    [string]$UFO_NUMBER = $filename.Substring(0,4)
    $spoParentdir ="$($UFO_NUMBER)\$($currentyear)"
    if(([regex]$UFO_NUMBER -match "^[1-3,5,8]\d\d\d$") -and (Test-Path -Path $fsFile -NewerThan $timeSpan))
    {
        Write-Host "[STATUS] : Processing: $($filename)." -ForegroundColor White -BackgroundColor Blue
        Sync-RetailReports -fileName $fileName -fsFile $fsFile -newParentdir $newParentdir -spoListName $spoListName -store $UFO_NUMBER -spoParentdir $spoParentdir -rootLabel $rootLabel -dfsparentdir $dfsparentdir 
    }
        else 
        {
            Write-Host "[WARNING] : Not copying $($fileName) to SharePoint because it does not match regex query, or is older than time frame specified in the `$timeFrame variable."
        }
}
$rootLabel = "PnL"
$dfsparentdir = "\\SERVER\SHARE\...\POS Initiatives\Reports for Store Distribution\Store_PnL_Reports\$($currentyear)"
$files = Get-ChildItem $dfsparentdir -Recurse -File | Where-Object{$stores -match $($_.Name).Substring(0,4)}
$files | 
ForEach-Object{
    $file = $_
    $newParentdir = $file.DirectoryName
    $fileName = $file.Name
    $fsFile = $file.FullName
    [string]$UFO_NUMBER = $filename.Substring(0,4)
    $spoParentdir =  "$($UFO_NUMBER)\$($currentyear)"
    if(([regex]$UFO_NUMBER -match "^[1-3,5,8]\d\d\d$") -and (Test-Path -Path $fsFile -NewerThan $timeSpan))
    {
        Write-Host "[STATUS] : Processing: $($filename)." -ForegroundColor White -BackgroundColor Blue
        Sync-RetailReports -fileName $fileName -fsFile $fsFile -newParentdir $newParentdir -spoListName $spoListName -store $UFO_NUMBER -spoParentdir $spoParentdir -rootLabel $rootLabel -dfsparentdir $dfsparentdir
    }
        else 
        {
            Write-Host "[WARNING] : Not copying $($fileName) to SharePoint because it does not match regex query, or is older than time frame specified in the `$timeFrame variable."
        }        
}
$rootLabel = "DB"
$dfsparentdir = "\\SERVER\SHARE\...\Stores"
$files = Get-ChildItem $dfsparentdir -Recurse -File | Where-Object{$stores -match $($_.Name).Substring(0,4)}
$files | 
ForEach-Object{
    $file = $_
    $newParentdir = $file.DirectoryName
    $fileName = $file.Name
    $fsFile = $file.FullName
    [string]$UFO_NUMBER = $filename.Substring(0,4)
    $spoParentdir = "$($UFO_NUMBER)\DropBox"
    if(([regex]$UFO_NUMBER -match "^[1-3,5,8]\d\d\d$") -and (Test-Path -Path $fsFile -NewerThan $timeSpan))
    {
        Write-Host "[STATUS] : Processing: $($filename)." -ForegroundColor White -BackgroundColor Blue
        Sync-RetailReports -fileName $fileName -fsFile $fsFile -newParentdir $newParentdir -spoListName $spoListName -store $UFO_NUMBER -spoParentdir $spoParentdir -rootLabel $rootLabel -dfsparentdir $dfsparentdir
    }
        else 
        {
            Write-Host "[WARNING] : Not copying $($fileName) to SharePoint because it does not match regex query, or is older than time frame specified in the `$timeFrame variable."
        }        
}
$stores | ForEach-Object{
    $store = $_
    Set-SpoPnpFolderPermission -foldername $store -spoListname $spoListName
}

Process-Output -message "$Script:ProductName script has completed. Detailed logs can be found under $Script:Logfile." -type "End" -status "Informational" -splunk $true -color "Magenta"
Exit
###########################################[SCRIPT END ]###########################################