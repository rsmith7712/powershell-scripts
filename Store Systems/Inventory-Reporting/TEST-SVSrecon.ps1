# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    TEST-SVSrecon.ps1

    .SYNOPSIS
    Connects to an FTP and downloads files.
    
    .DESCRIPTION
    Connects to StoredValue's FTP and pulls files down to a directory where another process ingests them.
    
    .NOTES
    Version:        1.0
    Author:         user4@example.com
    Creation Date:  03/16/18
    Purpose/Change: SVS changed their FTP backend. Updated with new parameters. Generated new fingerprint from public key.

    .HISTORY
    Version:        0.1 (11/17/16)
    Purpose/Change: Initial script creation.

.FUNCTIONALITY
    Connects to StoredValue's FTP and pulls files down to a directory where another process ingests them.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$localPath = "C:\temp\SVS\RCON\"
$remotePath = "/SAVUG/"
$filename = "savrq132"
$WinSCPpath = "C:\Program Files\WinSCP"

#https://winscp.net/eng/docs/library_examples 
try{
    # Load WinSCP .NET assembly
	Add-Type -Path "$WinSCPpath\WinSCPnet.dll"
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = "sftp.storedvalue.com" # New endpoint as of 3/16/18
        PortNumber = "22"
        UserName = "SAVUG"
        Password = "<password>"
        SshHostKeyFingerprint = "ssh-rsa 2048 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00" # New Public Key as of 3/16/18
        }
    $session = New-Object WinSCP.Session
    $session.ExecutablePath = "$WinSCPpath\WinSCP.exe"
	try
	{
		# Connect
		$session.Open($sessionOptions)
		
		# Format timestamp
		$stamp = $(Get-Date -Format "yyyyMMddHHmmss")
		
		# Download the file and throw on any error
		$session.GetFiles(
			($remotePath + $fileName),
			($localPath + $fileName + "." + $stamp)).Check()
	}
	finally
	{
		# Disconnect, clean up
		$session.Dispose()
	}
	exit 0
    }
catch [Exception]{
    Write-Host ("Error: {0}" -f $_.Exception.Message)
    exit 1
    }