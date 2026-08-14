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
    fStart-Transfer_2.ps1

.SYNOPSIS
  fStart-SftpTransfter.ps1
 
.DESCRIPTION
  fStart-SftpTransfter.ps1

.EXAMPLE
  fStart-SftpTransfter.ps1

.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  08/04/2020
  Purpose/Change: Initial Script Development

.HISTORY

.FUNCTIONALITY
    fStart-SftpTransfter.ps1

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

##################[INITIALIZATIONS]###################
Function Start-SftpTransfer{
Param (

    [parameter(Mandatory=$true)][string]$remotePath,
    [parameter(Mandatory=$true)][string]$localPath,
    [parameter(Mandatory=$true)][string]$HostName,
    [parameter(Mandatory=$true)][string]$Username,
    [parameter(Mandatory=$true)][string]$SshHostKeyFingerprint,
    [parameter(Mandatory=$true)][string]$Password
)
Try
    {
    # Load WinSCP .NET assembly
    Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = $HostName
        UserName = $Username
        SshHostKeyFingerprint = $SshHostKeyFingerprint
        Password = $Password
        }
    $session = New-Object WinSCP.Session
    Try
    {
    # Connect
    $session.Open($sessionOptions) 
    #$session | gm
    $files = @() #This is case sensitive.  Make sure the letter case is the same as that of the file being downloaded.
    $files = "testies123.xml" # Needs to be populated.
    Foreach ($file in $files){
        Write-Host "Downloading $file from $HostName..." -ForegroundColor Yellow
        $session.GetFiles($remotePath + $file, $localPath + $file, $false).Check() # '$true' here means that the file will be deleted from the source after the transfer completes.
        }
            $output = "SFTP file download from $HostName was successful."
            Write-Host $output -ForegroundColor Green
    }
        Finally
            {
                $session.Dispose()
            }
    }
    Catch
        {
            $output = "[ERROR] : SFTP file download from $HostName failed. The following exception occurred: $($_.Exception.Message)."
            Write-Host $output -ForegroundColor Red
            # Send_Failure_Email -body $output
            # Exit 1
        }
}

$xmlDestination = "\\SERVER\SHARE\...\Input"
$xlsDestination = "\\SERVER\SHARE\...\Input"
$amtBackupDestination = "\\SERVER\SHARE\...\AMT_Archives"

[string]$Password = "<password>"
[string]$Username = "ftp_171"
[string]$HostName = "sftp.amtdirect.com"
[string]$localPath = "C:\temp\amt_sftp\temp\"
[string]$remotePath = "/usr/ftp_171/Prod/"
[string]$SshPrivateKeyPath = "ssh-rsa 2048 rnEvFlnrzNc+NK7ztyZYs7vBHH3is83taNYYFbjIoHk="
Start-SftpTransfer -remotePath $remotePath -localPath $localPath -HostName $HostName -Username $Username -Password $Password -SshHostKeyFingerprint $SshPrivateKeyPath
<# 
    Requirements from Rick Davis
    Grab any files on their site that we deem need to be processed.
    This directory will contain various files, but the files we need to grab will be any files with the extension of either â€œ.xmlâ€ or â€œ.xlsâ€
#>