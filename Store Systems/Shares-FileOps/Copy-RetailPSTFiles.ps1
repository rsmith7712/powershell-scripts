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
    Copy-RetailPSTFiles.ps1

.SYNOPSIS
    Copy-RetailPSTFiles.ps1

.DESCRIPTION
    Copy-RetailPSTFiles.ps1
    
.EXAMPLE
    Copy-RetailPSTFiles.ps1
 
.NOTES
    Version:        v1.0
    Author:         user10
    Creation Date:  03/03/2020
    Purpose/Change: Initial script creation

.HISTORY

.FUNCTIONALITY
    Copy-RetailPSTFiles.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

###########################################[INITIALIZATIONS ]#######################################
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$script:uid =([string](Get-Date -UFormat "%y%m%d") + ".ATM." + [string](Get-Random -Minimum 1000000000 -Maximum 9999999999))
$Script:ProductName = "Copy-RetailPSTFiles"
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
Function Process-Output($splunk = $false,$message,$type = "Log",$status = "Informational",$color = "White")
{
    If($splunk)
    {
        Log_ToSplunk -Message $message -Type $type -Status $status
    }
    Append-Log $message
    Return-Output -message $message -color $color
}#=========================================[END Function]==========================================
Function Set-NtfsAclMailFolder($pstPath)
{
    $tkt = "domain\" + $script:store + "tkt"
    $mgr = "domain\" + $script:store + "mgr"
    $str = "domain\" + $script:store + "str"
    &icacls $pstPath /inheritance:d
    &icacls $pstPath /grant:r Administrators:'(CI)(OI)'F
    &icacls $pstPath /grant:r DOMAIN\ORGSvc:'(CI)(OI)'F
    &icacls $pstPath /grant:r DOMAIN\DESKTOP_STORE:'(CI)(OI)'F
    &icacls $pstPath /grant:r DOMAIN\DESKTOP_CORP:'(CI)(OI)'F
    &icacls $pstPath /grant:r $mgr`:'(CI)(OI)'M
    &icacls $pstPath /grant:r $str`:'(CI)(OI)'M
    &icacls $pstPath /grant:r $tkt`:'(CI)(OI)'RX
    &icacls $pstPath /remove:g "Users"
    &icacls $pstPath /remove:g "Authenticated Users"
    &icacls $pstPath /grant:r BUILTIN\Users:'(OI)(CI)(Rc,S,X)'
    $status = $?
    Process-Output -message "[STATUS] : Attempted to update NTFS ACL for $pstPath. Success Flag: $status."
}#=========================================[End Function ]=========================================
Function Set-NtfsAclMgrFile($mgrFile)
{
    $tkt = "domain\" + $script:store + "tkt"
    $str = "domain\" + $script:store + "str"
    &icacls $mgrFile /inheritance:d
    &icacls $mgrFile /remove $str
    &icacls $mgrFile /remove $tkt
    $status = $?
    Process-Output -message "[STATUS] : Attempted to update the NTFS ACL for $mgrFile. Success Flag: $status."
}#=========================================[End Function ]=========================================
Function Check-Path($st,$sharename)
{        
Try
    {
        If(Test-Path "\\$st\c$\$sharename" -ErrorAction Stop)
        {
            $output = "[STATUS] : SUCCESS: \\$st\c$\$sharename is accessible";$rc = 0
        }
            else
            {
                $output = "[STATUS] : WARNING: The folder path \\$st\c$\$sharename was not found.";$rc = 1
            }
    }
    Catch
        {
            $output = "[STATUS] : ERROR: The folder path: \\$st\c$\$sharename is not accessible from the CORE computer. Exception Message: $($_.Exception.Message).";$rc = 2
        }
    Process-Output -message $output -color cyan 
    return $rc
}#=========================================[End Function]==========================================
Function Get-Creds
{
    # Set credentials for account executing script
    $username = "domain\orgsvc"
    $password = ConvertTo-SecureString -AsPlainText -Force -String "<password>"
    $script:cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username,$password
}#=========================================[End Function]==========================================
Function Get-CopyIssues($robolog)
{
    $issues = Get-Content $robolog|findstr /I "ERROR"|findstr /I "(0x0"
    Write-Host ""
    Write-Host "File copy issues ('Blank' means no issues):" -ForegroundColor White
    $issues | 
        ForEach-Object {
            Process-Output -message $_
        }
    
}#=========================================[End Function]==========================================
###########################################[SCRIPT STARTS ]########################################
Check-RunAsAdministrator
Process-Output -message "[STATUS] : Script Starting" -type "Begin"
#-------------------------------------------[Variables]--------------------------------------------
[string]$script:store = $env:COMPUTERNAME.Substring(0,4)# prod 
$mailPath = "D:\Shares\Mail" # prod 
#test $script:store = "1959"
#test $mailPath = "c:\mail" 
$shareName = $mailPath.split("\")[-1]
$st = $script:store + "st"
# Rebuild-Test
#--------------------------------------------------------------------------------------------------
if(!(Test-Path $($mailPath))){mkdir $mailPath}
Try
{
    New-SmbShare -Name $shareName -Path $mailPath -FullAccess "Everyone"
    $output = "[STATUS] : SUCCESS: $mailPath shared successfully"
}
    Catch
    {
        $output = "[STATUS] : ERROR: unable to share $mailPath. Exception Message: $($_.Exception.Message)"
    }
Finally
{
    $ErrorActionPreference = "SilentlyContinue"
}
Process-Output -message $output
Try
{
    Get-Creds
    $robolog = "C:\temp\robocopy_log_$shareName.txt"
    #Test access to ST computer folder shares.
    $testaccess = Check-Path -st $st -sharename $shareName
    if ($testaccess -eq 0)
    {
        Start-Process -Wait ROBOCOPY -WorkingDirectory "C:\Windows\System32" -argumentlist "\\$st\c$\$shareName $mailPath /E /XA:H /LOG:$robolog /FP /MT /R:1 /W:1 /FFT /Z /NP" -Credential $script:cred
    }
}
    Catch
    {
        $output = "[STATUS] : ERROR: ROBOCOPY \\$st\c$\$shareName failed. Exception Message: $($_.Exception.Message)"
        Process-Output -message $output
    }
$sourcecount = (Get-ChildItem "\\$st\c$\$shareName" -Attributes !Directory+!Hidden -recurse | Measure-Object -property length).count
$destcount = (Get-ChildItem $mailPath -Attributes !Directory+!Hidden -recurse | Measure-Object -property length).count
$difference = $sourcecount - $destcount
if($($difference) -gt 0)
{
    $output = "[STATUS] : WARNING: $($difference) files were not copied from \\$st\c$\$shareName to $mailPath. Review the robocopy logs located under c:\logs on the CORE computer."
    Process-Output -message $output
}
    else
    {
        $output = "[STATUS] : SUCCESS: All $($sourcecount) files were successfully copied from \\$st\c$\$shareName to $mailPath"
        Process-Output -message $output
    }
    Set-NtfsAclMailFolder -pstPath $mailPath
    $mail = Get-ChildItem $mailPath
    $mail | 
        ForEach-Object {
            if ($_.Name -match "mgr")
            {
                $mgrFileName = $_.Name
                $mgrFile = $_.FullName
                $status = "[STATUS] : $mgrFileName has been identified as a Manager file. Applying restricted NTFS permissions to this file."
                Write-Host $status -ForegroundColor White -BackgroundColor Blue
                Set-NtfsAclMgrFile -mgrFile $mgrFile
            }
        }
$exitLog = Get-Content $Script:Logfile        
Log_ToSplunk -Message $exitLog -Type "End" -Status "Informational"
Append-Log "Script Ending"
" " | Out-File $Script:Logfile -Append
Exit
###########################################[SCRIPT END]###########################################    