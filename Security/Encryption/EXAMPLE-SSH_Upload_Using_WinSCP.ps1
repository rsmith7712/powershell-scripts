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
    EXAMPLE-SSH_Upload_Using_WinSCP.ps1

.DESCRIPTION
    Example function to upload files over SFTP/SSH using the WinSCP .NET assembly.

.FUNCTIONALITY
    Uploads files over SFTP via WinSCP (example).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Upload-Files{
Param(
    [parameter(Mandatory=$false)]
    [String]
    $localPath = "C:\temp\test",

    [parameter(Mandatory=$false)]
    [String]
    $remotePath = "/Datafeed/",

    [parameter(Mandatory=$false)]
    [String]
    $HostName = "ftp.domainuniversityonline-pilot.csod.com",

    [parameter(Mandatory=$false)]
    [String]
    $username = "domainuniversityonline",

    [parameter(Mandatory=$false)]
    [String]
    $pw = "<password>",

    [parameter(Mandatory=$false)]
    [String]
    $SshHostKeyFingerprint = "ssh-dss 1024 2pRuq32xctaJIENCIvSxNvb0B1jJ5mEqSDyKb4ZFfIU="
)
Try
{
    # Load WinSCP .NET assembly
    Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
 
    # Setup SSH session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = $HostName
        UserName = $username
        Password = $pw
        SshHostKeyFingerprint = $SshHostKeyFingerprint
    }
 
    $session = New-Object WinSCP.Session
 
    Try
    {
        # Connect
        $session.Open($sessionOptions) 
        $remotePath = "/Datafeed/" 
 
        Get-ChildItem "$localPath" | foreach{
            $file = "$localPath\$_"
            Write-Host "Uploading $file ..."
            
            # Copy Files
            $session.PutFiles($file, $remotePath).Check()
        }
    }
    Finally
    {
        # Disconnect, clean up
        $session.Dispose()
    }
 
    exit 0
    }
Catch
    {
        # Capture Error(s)
        Write-Host "Error: $($_.Exception.Message)"
        exit 1
    }

}

Upload-Files