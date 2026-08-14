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
    fStart-SftpQuery.ps1

.DESCRIPTION
    Opens a WinSCP SFTP session to a vendor host to query and transfer files.

.FUNCTIONALITY
    Opens a WinSCP SFTP session.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

[string]$localPath = "C:\temp\amt_sftp\temp\"
[string]$remotePath = "/usr/ftp_171/Prod/"

# Load WinSCP .NET assembly
Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

# Set up session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = "sftp.amtdirect.com"
    UserName = "ftp_171"
    Password = "<password>"
    SshHostKeyFingerprint = "ssh-rsa 2048 rnEvFlnrzNc+NK7ztyZYs7vBHH3is83taNYYFbjIoHk="
}
$session = New-Object WinSCP.Session

try
{
    # Connect
    $session.Open($sessionOptions)
 
        # Get list of files in the directory
        $directoryInfo = $session.ListDirectory($remotePath)
 
        # Select the most recent file
        $latest =
            $directoryInfo.Files |
            Where-Object { -Not $_.IsDirectory } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
 
        # Any file at all?
        if ($latest -eq $Null)
        {
            Write-Host "No file found"
            exit 1
        }
 
        # Download the selected file
        $session.GetFiles(
            [WinSCP.RemotePath]::EscapeFileMask($latest.FullName), $localPath).Check()
}
finally
{
    $session.Dispose()
}