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
    Migrate-SPOSscReportsSAPL.ps1

.Pending
    - Set applicable SPO permissions.
    - Recieve errors from file copy PS jobs
    - Configure Logging (local/splunk)
    DONE - Copy updated files ONLY to the new SPO directories.
    DONE - Prevent script from creating 'Are you missing a file - contact Ahlyshawndra Means' folders.
    DONE - Copy files to the new SPO directories.

.SYNOPSIS
    Migrate-SPOSscReportsSAPL.ps1

.DESCRIPTION
    Migrate-SPOSscReportsSAPL.ps1
    Read more: http://www.sharepointdiary.com/2015/01/run-powershell-script-as-administrator-automatically.html
    
.EXAMPLE
    Migrate-SPOSscReportsSAPL.ps1
 
.NOTES
    Version:        v1.1
    Author:         user10
    Creation Date:  12/10/2019
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Migrate-SPOSscReportsSAPL.ps1
        Read more: http://www.sharepointdiary.com/2015/01/run-powershell-script-as-administrator-automatically.html

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
<#
[cmdletbinding()]
param
(
    [string]$param1
    [string]$<ParamName> = $(throw "[ERROR] : -<ParamName> parameter is required.")
    [ValidateSet('item1','item2')]    
)
#>
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Migrate-SPOSscReportsSAPL"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){rm $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
###########################################[FUNCTIONS ]############################################
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
Function Append-Log
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$message
    )
    $thetime = Get-Date -Format g
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=========================================[End Function ]=========================================
Function Return-Output
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$message,
        [parameter(Mandatory=$false,Position=1)][string]$color="White"
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
}#=========================================[End Function ]=========================================
Workflow Copy-ReportsFsSpo
{
    [cmdletbinding()]
    param
    (
        [int]$ThrottleLimit = 50
    )
    $dfsparentdir = "\\SERVER\SHARE\...\SAPL"
    $parent = Get-Item $dfsparentdir | Where-Object{$_.PSIsContainer}
    ForEach -parallel -throttlelimit $ThrottleLimit ($child in $parent){
        InlineScript
        {
            Function Get-FolderStructure($parentdir)
            {
                Get-ChildItem $parentdir | Where-Object{ $_.PSIsContainer} |
                    ForEach-Object{
                                    [string]$fullpath = $_.FullName
                                    $newfolder = $fullpath.Split("\")[-1]
                                    return $newfolder
                                  }
            }#-----------------------------[End Function]------------------------------------------
            $username = "flowautomation@example.com"
            $password = "<password>"
            $spolistname = "CorporateReports"
            $spoparentdir = $spolistname + "\SAPL"
            $spourl = "https://domain.sharepoint.com/sites/TheA-Team"
            $cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
            #--------------------------------------------------------------------------------------
            Try
            {
                $moduleversion = (Import-Module "SharePointPnPPowerShellOnline" -PassThru -Force).Version
                $status = "[SUCCESS] : PS module 'SharePointPnPPowerShellOnline' version: $moduleversion imported successfully."
            }
                Catch
                {
                    $status = "[WARNING] : Failed to import PS module 'SharePointPnPPowerShellOnline.' Attemping to install module. The following exception occurred: $($_.Exception.Message)."
                }#-------------------------[END Try/Catch]-----------------------------------------
            Try
            {
                Connect-PnPOnline -Url $spourl -Credentials $cred
            }
                Catch
                {
                    $status = "[ERROR] : Failed to connect to $($spourl) as $($username). The following exception occurred: $($_.Exception.Message)."
                }#-------------------------[END Try/Catch]-----------------------------------------
            Get-ChildItem -Recurse "$using:child" | Where-Object{ $_.PSIsContainer} |
            ForEach-Object{
                    $newparentdir = ($_.FullName)
                    $spopath = $newparentdir.Replace("$using:dfsparentdir",$using:spoparentdir)
                    if ((Get-ChildItem $newparentdir -File).Exists)
                    {
                        Get-ChildItem $newparentdir -File | 
                        ForEach-Object{
                                        $File = $_.Name
                                        $spFile = "$spopath\$file"
                                        $fsFile = $_.FullName
                                        $spModified = $spFile.TimeLastModified
                                        $fsModified = $_.LastWriteTime
                                        Write-Host "File Server File Time Stamp: $fsModified"
                                        Write-Host "SharePoint File Time Stamp: $spModified"
                                        if(($spFile -eq $null) -or ($spModified -lt $fsModified))
                                        {
                                            Write-Host "Copying: $fsFile"
                                            $folder = $spopath
                                            $scriptblock = Add-PnPFile -Path $fsFile -Folder $folder
                                            Start-Job -ScriptBlock{$using:scriptblock}
                                        }
                                      }
                        $runningcount = (Get-Job | Where-Object{$_.State -eq "Running"}).count
                        $suspendedcount = (Get-Job | Where-Object{$_.State -eq "Suspended"}).count
                        Write-Host "Jobs Running: $($runningcount)`nJobs Suspended: $($suspendedcount)"
                        Get-Job | Where-Object{$_.State -ne "Running"} | Receive-Job
                        Get-Job | Where-Object{$_.State -eq "Running"} | Wait-Job | Receive-Job
                    }
                    Get-FolderStructure -parentdir $newparentdir | ForEach-Object{
                    $new = $_
                    if(($new -notmatch "Are you missing a file") -and ($new -notmatch "If you are missing a file"))
                    {
                        Write-Host "Creating Folder '$spopath\$new'"                                    
                        Add-PnPFolder -Name $($new) -Folder $($spopath)
                    }#---------------------[END If]------------------------------------------------
                }#-------------------------[END ForEach]-------------------------------------------
            }#-----------------------------[END ForEach]-------------------------------------------
        }#---------------------------------[END InlineScript]--------------------------------------
    }#-------------------------------------[END ForEach]-------------------------------------------
}#=========================================[END WORKFLOW]==========================================
Function Process-Output($splunk = $false,$message,$type = "Log",$status = "Informational",$color = "White")
{
    If($splunk)
    {
        Log_ToSplunk -Message $message -Type $type -Status $status
    }
    Append-Log $message
    Return-Output -message $message -color $color
}#=========================================[END Function]==========================================
###########################################[SCRIPT STARTS ]########################################
Process-Output -message "Initiating $Script:ProductName script execution." -type "Begin" -status "Informational" -splunk $true -color "Magenta"
# Create parent SPO directory, then call workflow to complete the process
$username = "flowautomation@example.com"
$password = "<password>"
$dfsparentdir = "\\SERVER\SHARE\...\SAPL"
$spolistname = "CorporateReports"
$spoparentdir = $spolistname + "\SAPL"
$spourl = "https://domain.sharepoint.com/sites/TheA-Team"
$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
#--------------------------------------------------------------------------------------------------
Try
{
    $moduleversion = (Import-Module "SharePointPnPPowerShellOnline" -PassThru -Force).Version
    $message = "[SUCCESS] : PS module 'SharePointPnPPowerShellOnline' version: $moduleversion imported successfully."
    Process-Output -message $message -type "Log" -status "Success" -color "Green"
}
    Catch
    {
        $message = "[WARNING] : Failed to import PS module 'SharePointPnPPowerShellOnline.' Attempting to install module. The following exception occurred: $($_.Exception.Message)."
        Process-Output -message $message -type "Log" -status "Warning"
    }
#--------------------------------------------------------------------------------------------------
Connect-PnPOnline -Url $spourl -Credentials $cred
#--------------------------------------------------------------------------------------------------
Try
{
    Add-PnPFolder -Name "SAPL" -Folder $($spolistname)
    Process-Output -message "[SUCCESS] : Successfully created '/SAPL' Parent folder" -type "Log" -status "Success" -color "Green"
}
    Catch
    {
        $message = "[ERROR] : Exception Message: $($_.Exception.Message)."
        Process-Output -message $message -type "Log" -status "Error" -splunk $true -color "Red"
    }
    Get-ChildItem $dfsparentdir | Where-Object{$_.PSIsContainer} |
    ForEach-Object{
                    Try
                    {
                        Add-PnPFolder -Name $($_.Name) -Folder $($spoparentdir)
                        Process-Output -message "Creating SPO folder '$($_.Name)' under '$($spoparentdir).'" -type "Log" -status "Success" -color "Green"
                    }
                        Catch
                        {
                            $message = "[ERROR] : Exception Message: $($_.Exception.Message)."
                            Process-Output -message $message -type "Log" -status "Error" -splunk $true$true -color "Red"
                        }
                  }
#--------------------------------------------------------------------------------------------------
Copy-ReportsFsSpo
#--------------------------------------------------------------------------------------------------
Process-Output -message "Completing $Script:ProductName script execution." -type "End" -status "Informational" -splunk $true -color "Magenta"
###########################################[SCRIPT END ]###########################################