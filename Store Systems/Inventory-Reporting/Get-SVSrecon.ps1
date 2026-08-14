# LEGAL
<# LICENSE
    MIT License, Copyright 2019 Richard Smith

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
    Get-SVSrecon.ps1

    .SYNOPSIS
        Connects to an FTP and downloads files.
    
    .DESCRIPTION
        Connects to StoredValue's FTP and pulls files down to a directory where another process ingests them.
    
    .NOTES
        Version:        1.1
        Author:         user10 [user2@example.com]
        Creation Date:  11/18/2019
        Purpose/Change: Organized into functions to support multiple target files.

    .HISTORY
        Version:        1.0 (03/16/18)
        Author:         user4@example.com
        Purpose/Change: SVS changed their FTP backend. Updated with new parameters. Generated new fingerprint from public key.

        Version:        0.1 (11/17/16)
        Purpose/Change: Initial script creation.

.FUNCTIONALITY
    Connects to StoredValue's FTP and pulls files down to a directory where another process ingests them.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

######################################[INITIALIZATIONS]#######################################
Clear-Host
$script = "Get-SVSrecon.ps1"
New-EventLog -LogName "Application" -Source $script -ErrorAction SilentlyContinue
$Error.Clear()
$DebugPreference = "Continue"
$InformationPreference = "Continue"
if (Test-Path "$env:ProgramFiles\WinSCP"){$WinSCPpath = "$env:ProgramFiles\WinSCP"}
if (Test-Path "${env:ProgramFiles(x86)}\WinSCP"){$WinSCPpath = "${env:ProgramFiles(x86)}\WinSCP"}
#########################################[FUNCTIONS]##########################################
Function Get-SFTPFiles($file)
{#https://winscp.net/eng/docs/library_examples
    $Environment = "Test" # test or prod
    if ($env:COMPUTERNAME -eq "ts0-fsc-app2"){$Environment = "test"}
    if ($env:COMPUTERNAME -eq "srv"){$Environment = "prod"}    
    switch($Environment)
    {
    "Test"
        {
            $ftpHostName = "testsftp.storedvalue.com";
            $ftpUserName = "SAVUG-UAT";
            $ftpPassword = "<password>";
            $remotePath = "/";
            $localPath = "C:\temp\SVS\RCON\";
            $filename = $file ;#"Download-Test.txt"
        }
    "Prod"
        {
            $ftpHostName = "sftp.storedvalue.com";
            $ftpUserName = "SAVUG";
            $ftpPassword = "<password>";
            $remotePath = "/";
            $localPath = "C:\temp\SVS\RCON\";
            $filename = $file ;#("SAVRQ132","SASVM132");
        }
    }
    Write-Debug "script: $script"
    Write-Debug "WinSCPpath: $WinSCPpath"
    Write-Debug "Environment: $Environment"
    Write-Debug "ftpHostName: $ftpHostName"
    Write-Debug "ftpUserName: $ftpUserName"
    Write-Debug "remotePath: $remotePath"
    Write-Debug "localPath: $localPath"
    Write-Debug "filename: $filename"
    try
    {
    # Load WinSCP .NET assembly
        Add-Type -Path "$WinSCPpath\WinSCPnet.dll"
    # Setup session options
        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol = [WinSCP.Protocol]::Sftp;
            HostName = $ftpHostName;
            PortNumber = 22;
            UserName = $ftpUserName;
            Password = $ftpPassword;
            SshHostKeyFingerprint = "ssh-rsa 2048 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00"
    }
    $session = New-Object WinSCP.Session
    $session.ExecutablePath = "$WinSCPpath\WinSCP.exe"
    try 
    {
    # Connect
        $session.Open($sessionOptions)
    # Format timestamp
        $stamp = $(Get-Date -Format "yyyyMMddHHmmss")
        if (!(Test-Path $localPath)){mkdir $localPat}
    # Download the file and throw on any error
        "downloading ${ftpHostName}${remotePath}${filename} to ${localPath}${filename}.${stamp}"
        $session.GetFiles(
            ($remotePath + $fileName),
            ($localPath + $fileName + "." + $stamp)).Check()
        "success"
        Write-EventLog -LogName "Application" -Source $script -EventId 1 `
            -Message "downloaded ${ftpHostName}${remotePath}${filename} to ${localPath}${filename}.${stamp}" `
            -ErrorAction SilentlyContinue
    } 
        catch 
        {
            $Exception = $_.Exception
            Write-Warning $Exception.Message
            Write-EventLog -LogName "Application" -Source $script -EventId 2 -EntryType Error `
                -Message $Error[0].Exception.Message `
                -ErrorAction SilentlyContinue
        } 
        finally
        {
        # Disconnect, clean up
            $session.Dispose()
        }
    $returnvalue = "0" #exit 0
    }
        catch [Exception]
        {
            $Exception = $_.Exception
            Write-Error $Exception.Message
            Write-EventLog -LogName "Application" -Source $script -EventId 3 -EntryType Error `
                -Message $Error[0].Exception.Message `
                -ErrorAction SilentlyContinue
            $returnvalue = "1" #exit 1
        }
    return $returnvalue
}#===================[End Function]===================
#######################################[SCRIPT STARTS]########################################
$files = @("SAVRQ132","SASVM132")
$files |
ForEach-Object {
                $status = Get-SFTPFiles -file $_
                $output = "Filename: $($_) Status: (0 = success, 1 = failure): $($status)."
                Write-Host $output  -ForegroundColor Yellow
               }
Exit
#########################################[SCRIPT END]######################################### 