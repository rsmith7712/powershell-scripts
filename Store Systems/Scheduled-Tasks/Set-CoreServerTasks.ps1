# LEGAL
<# LICENSE
    MIT License, Copyright 2021 Richard Smith

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
    Set-CoreServerTasks.ps1

.SYNOPSIS
    Set-CoreServerTasks.ps1

.DESCRIPTION
    Set-CoreServerTasks.ps1 - runs locally on the Core server to create folders, shares, NTFS permissions, and scheduled tasks
    for store reports and operations.
    
.EXAMPLE
    Set-CoreServerTasks.ps1
 
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  2/15/2021
  Purpose/Change: Initial development

.HISTORY

.FUNCTIONALITY
    Set-CoreServerTasks.ps1 - runs locally on the Core server to create folders, shares, NTFS permissions, and scheduled tasks
        for store reports and operations.

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
$script:ScriptName = "Set-CoreServerTasks.ps1"
[string]$script:datestamp = (Get-Date).ToString("yyyyMMdd")
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Set-CoreServerTasks"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
$Script:FixMe = "$script:script_dir\logs\$($Script:ProductName)_FixMe.log"
if(!(Test-Path "$script:script_dir\logs")){mkdir "$script:script_dir\logs"}
if(Test-Path $Script:Logfile){Remove-Item $Script:Logfile}
$ErrorActionPreference = "SilentlyContinue"
##############################################[FUNCTIONS]#############################################
Function Append-Log
{
    param
    (
        [parameter(Mandatory=$true,Position=0)][string]$message,
        [parameter(Mandatory=$false,Position=1)][string]$color = "White"
    )
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=======================================[ End Function ]==========================================
Function Copy-CoreScripts($srcDir,$destDir)
{
    Try
    {
        Copy-Item "$($srcDir)\STMigrate-SyncShares.ps1" -Destination "$($destDir)\STMigrate-SyncShares.ps1" -Force
        Copy-Item "$($srcDir)\hourlytask.bat" -Destination "$($destDir)\hourlytask.bat" -Force
        Copy-Item "$($srcDir)\Sync-SPreports.ps1" -Destination "$($destDir)\Sync-SPreports.ps1" -Force 
        Copy-Item "$($srcDir)\Check-DartsVersion.ps1" -Destination "$($destDir)\Check-DartsVersion.ps1"
        Append-Log -message "[STATUS] : Copied required scripts to the Core computer." 
    }
        Catch
        {
            Append-Log -message "[WARNING] : Failed to copy scripts to $computer. Exception Message: $($_.Exception.Message)"
        }
}#=======================================[ End Function ]==========================================
Function Deploy-Schtasks($computer)
{
  SCHTASKS /CREATE /F /s $computer /TN "STMigrate-SyncShares" /RU "domain\orgsvc" /RP "<password>" /SC "DAILY" /ST "01:30" /RI "120" /DU "24:00" /TR "Powershell -executionpolicy bypass -file C:\temp\STMigrate-SyncShares.ps1"
  SCHTASKS /CREATE /s $computer /TN "Darts_Updater" /SC "Daily" /RU "domain\orgsvc" /RP "<password>" /ST "04:00" /TR "powershell.exe -executionpolicy bypass -file C:\temp\Check-DartsVersion.ps1" /f
  SCHTASKS /CREATE /F /s $computer /TN "HourlyTask" /RU "domain\domainscheduler" /RP '<password>' /SC "DAILY" /ST "01:00" /RI "60" /DU "24:00" /TR "C:\temp\hourlytask.bat"
  If ($LASTEXITCODE -ne 0)
  {
    Append-Log -message "[ERROR] : Scheduled migration task creation failed on $computer. Exit Code: $($LASTEXITCODE). Exception Message:$($_.Exception.Message)."
  }
    else
    {
      Append-Log -message "[Status] : Scheduled migration task creation step succeeded on $computer. Exit Code: $($LASTEXITCODE)."
    }
}#=======================================[ End Function ]==========================================
#########################################[Script Starts]###########################################
$store = $env:COMPUTERNAME.Substring(0,4)

# Define store user account variables
$tkt = "domain\" + $store + "tkt"
$mgr = "domain\" + $store + "mgr"
$str = "domain\" + $store + "str"

# Identify folders to be migrated
$folders = @(
    "C:\DartS",
    "D:\Shares\mail",
    "D:\Shares\DOCS",
    "D:\Shares\DOCS\Manager",
    "D:\Shares\REPORTS"
    )
$folders | ForEach-Object {
    # create folder, share, and assign share permissions
    $folderpath = $_
    $sharename = $_.split("\")[-1]
    if(!(Test-Path $($folderpath)))
    {
        mkdir $folderpath
    }
    &icacls $folderpath /inheritance:d
    &icacls $folderpath /grant:r Administrators:'(CI)(OI)'F
    &icacls $folderpath /grant:r DOMAIN\ORGSvc:'(CI)(OI)'F
    &icacls $folderpath /grant:r DOMAIN\DESKTOP_STORE:'(CI)(OI)'F
    &icacls $folderpath /grant:r DOMAIN\DESKTOP_CORP:'(CI)(OI)'F
    &icacls $folderpath /grant:r $mgr`:'(CI)(OI)'M
    &icacls $folderpath /grant:r $str`:'(CI)(OI)'M
    &icacls $folderpath /grant:r $tkt`:'(CI)(OI)'RX
    &icacls $folderpath /remove:g "Users"
    &icacls $folderpath /remove:g "Authenticated Users"
    &icacls $folderpath /grant:r BUILTIN\Users:'(OI)(CI)(Rc,S,X)'

    if($sharename -like "Manager" -or $sharename -like "mail")
    {
        &icacls $folderpath /inheritance:d
        &icacls $folderpath /remove:g $str
        &icacls $folderpath /remove:g $tkt
    }

    if($sharename -notlike "Manager" -and $sharename -notlike "mail")
    {
        Try
        {
            New-SmbShare -Name $sharename -Path $folderpath -FullAccess "Everyone"
            $output = "SUCCESS: $folderpath shared successfully"
            Append-Log $output
        }
            Catch
            {
                $output = "ERROR: unable to share $folderpath. Exception Message: $($_.Exception.Message)"
                Append-Log $output
            }
        Finally
        {
            $ErrorActionPreference = "SilentlyContinue"
        }
    }
}
Copy-CoreScripts -srcDir "\\SERVER\SHARE\...\core" -destDir "C:\scripts"
Deploy-Schtasks -computer $($env:COMPUTERNAME)

EXIT
#########################################[Script Ends]#############################################