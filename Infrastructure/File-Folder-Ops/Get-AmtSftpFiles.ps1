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
    Get-AmtSftpFiles_2.ps1

.SYNOPSIS
  Get-AmtSftpFiles.ps1
 
.DESCRIPTION
  Get-AmtSftpFiles.ps1

.EXAMPLE
  Get-AmtSftpFiles.ps1

.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  08/14/2020
  Purpose/Change: Initial Script Development

.HISTORY

.FUNCTIONALITY
    Get-AmtSftpFiles.ps1

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
$Script:ProductName = "Get-AmtSftpFiles"
$Script:Logfile = "$script:script_dir\logs\$($Script:ProductName).log"
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
        [parameter(Mandatory=$false)][string]$splunk = $false,
        [parameter(Mandatory=$false)][string]$splunkType,
        [parameter(Mandatory=$false)][string]$splunkStatus,
        [parameter(Mandatory=$false)][string]$color = "white"
    )
    If($splunk)
    {
        Log_ToSplunk -Message $message -Type $splunkType -Status $splunkStatus
    }
    $ErrorActionPreference = "SilentlyContinue"
    $thetime = Get-Date -Format g
    Write-Host "$thetime`: $message" -ForegroundColor $color
    "$thetime`: $message" | Out-File $script:logfile -Append
}#=========================================[END Function]==========================================
Function Copy-SftpFile
{
param (
    [parameter(Mandatory=$true)][string]$hostname ,
    [parameter(Mandatory=$true)][string]$remotePath,
    [parameter(Mandatory=$true)][string]$localPath,
    [parameter(Mandatory=$true)][string]$wildcard,
    [string]$localBox = $env:COMPUTERNAME
)
    try
    {
        # Load WinSCP .NET assembly
        Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
 
        # Setup session options
        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol = [WinSCP.Protocol]::Sftp
            HostName = $hostname
            UserName = "ftp_171"
            Password = "<password>"
            SshHostKeyFingerprint = "ssh-rsa 2048 rnEvFlnrzNc+NK7ztyZYs7vBHH3is83taNYYFbjIoHk="
        }
        $session = New-Object WinSCP.Session
        try
        {
            # Connect
            $session.Open($sessionOptions)
            # Get list of matching files in the directory
            $files =
                $session.EnumerateRemoteFiles(
                    $remotePath, $wildcard, [WinSCP.EnumerationOptions]::None
                    )
            # Any file matched?
            if ($files.Count -gt 0)
            {
                foreach ($fileInfo in $files)
                {
                    $fileName = $fileInfo.Name
                    $fileModified = $fileInfo.LastWriteTime
                    $session.GetFiles([WinSCP.RemotePath]::EscapeFileMask($fileInfo.FullName), $localPath, $false).Check()
                    $output = "[SUCCESS] : Downloaded '$fileName' with LastWriteTime: '$fileModified' from '$hostname'.";$color = "Green"
                    Process-Output -message $output -color $color
                }
            }
            else
            {
                $output = "[WARNING] : No files matching '$wildcard' found on '$hostname'. Exiting.";$color = "Yellow"
                Process-Output -message $output -color $color
                #Send-SmtpMail -body $output
                Exit
            }
        }
        finally
        {
            # Disconnect, clean up
            $session.Dispose()
        }
    }
    catch
    {
        $output = "[ERROR] : SFTP file download from '$HostName' to '$localBox' failed. The following exception occurred: $($_.Exception.Message).";$color = "Red"
        Process-Output -message $output -color $color
        Send-SmtpMail -body $output
        Exit
    }
}#=========================================[End Function]==========================================
Function Send-Files
{
param(
    [parameter(Mandatory=$false)][String]$tempfolder,
    [parameter(Mandatory=$false)][String]$archive,
    [parameter(Mandatory=$false)][String]$destination
)
    $timestamp = (Get-Date).ToString("yyyyMMdd-hhmmss")
    $filecount = (Get-ChildItem $tempfolder | Measure-Object).Count
    Try
    {
        if( $filecount -eq 0)
        {
            $output = "[WARNING] : No files found under $tempfolder to archive.  Exiting script.";$color = "Yellow"
        }
            else
            {
                Write-Host "$filecount files found. Archiving..." -ForegroundColor Yellow
                Get-ChildItem $tempfolder | 
                ForEach-Object{
                    [string]$file = $_
                    $name = $file.Split(".")[0]
                    $ext = $file.Split(".")[1]
                    $newname = $name + "_" + $timestamp + "." + $ext
                    Copy-Item -Path "$tempfolder\$file" -Destination $destination -Force
                    Move-Item -Path "$tempfolder\$file" -Destination "$archive\$newname" -Force
                    $output = "[SUCCESS] : $file successfully archived to '$archive\$newname.'";$color = "Green"
                    Process-Output -message $output -color $color
                }
            }
    }
        Catch
        {
            $output = "[ERROR] : File archiving failed. $($_.Exception.Message)";$color = "Red"
            Process-Output -message $output -color $color
        }
    Process-Output -message $output -color $color
}#=========================================[End Function]==========================================
Function Send-SmtpMail($body)
{
   $smtp = "smtpi.example.com"
   $to = "a-team@example.com"
   $from = "Domain Automation <donotreply@example.com>"
   $subject = "AMT SFTP File Transfer Status"                                                        
   Send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body
}#=========================================[End Function]==========================================

#########################################[ SCRIPT STARTS ]#########################################
Clear-Host
Process-Output -message "Script Starts"
#Log_ToSplunk -Message "Script Starts" -Type "Begin"
[string]$xmlDestination = "\\SERVER\SHARE\...\Input"
[string]$xlsxDestination = "\\SERVER\SHARE\...\Input"
[string]$amtBackupDestination = "\\SERVER\SHARE\...\AMT_Archives"
[string]$hostname = "sftp.amtdirect.com"
[string]$remotePath = "/usr/ftp_171/Prod/"
[string]$localPath = "C:\temp\amt_sftp\temp\"
$wildcards = @()
$wildcards = "*.xml","*.xlsx"

foreach ($wildcard in $wildcards)
{
    Copy-SftpFile -remotePath $remotePath -localPath $localPath -wildcard $wildcard -hostname $hostname
    if ($wildcard -like "*.xml")
    {
        Send-Files -tempfolder $localPath -archive $amtBackupDestination -destination $xmlDestination
    }
    elseif ($wildcard -like "*.xlsx")
    {
        Send-Files -tempfolder $localPath -archive $amtBackupDestination -destination $xlsxDestination
    }
}
Process-Output -message "Script Ends"
#Log_ToSplunk -Message "Script Starts" -Type "End"
#########################################[ SCRIPT ENDS ]###########################################