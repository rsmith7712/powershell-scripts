# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Network-SFTPsync.ps1

.SYNOPSIS
  Syncronizes a network share with TDX's SFTP.
 
.DESCRIPTION
  Connects to TDX's SFTP using a WinSCP .DLL, syncronizes changes from the network share.
  
.NOTES
  Version:        1.1
  Author:         user26
  Creation Date:  06/12/2018
  Purpose/Change: Added sync directories and Splunk.

.HISTORY
  Version:        1.0 (06/11/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Connects to TDX's SFTP using a WinSCP .DLL, syncronizes changes from the network share.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "NetTDXsync" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "Inquire" #Maybe change to "SilentlyContinue" for Production.
$DLLdir = "C:\Program Files\WinSCP\WinSCPnet.dll"
# Load WinSCP .NET assembly
Add-Type -Path $DLLdir

# Variables
#################################
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = "sftp.webtrax.tdxtech.com"
    UserName = "sftpdomain"
    Password = "<password>"
    SshHostKeyFingerprint = "ssh-ed25519 256 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00"
}
$LocalDir = "\\SERVER\SHARE\...\TDX Configs"
$RemoteDir = "/SFTP_Domain/Configs"

# Functions
#################################
function Log_ToSplunk{
    Param(
    [parameter(Mandatory=$true,
    Position=0)]
    [String]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    [String]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    [String]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
    [int]
    $ID = $Null
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
        }
    }
    $body = $body | ConvertTo-Json
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
    }

# Script
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"
 
# Session.FileTransferred event handler
function FileTransferred($file){
    if ($file.Error -eq $Null){
        #Write-Host "Upload of $($file.FileName) succeeded"
        Log_ToSplunk -Message "Upload of $($file.FileName) succeeded" -Type "Log" -Status "Informational"
    }
    else{
        #Write-Host "Upload of $($file.FileName) failed: $($file.Error)"
        Log_ToSplunk -Message "Upload of $($file.FileName) failed: $($file.Error)" -Type "Log" -Status "Informational"
    }
 
    if ($file.Chmod -ne $Null){
        if ($file.Chmod.Error -eq $Null){
            #Write-Host "Permissions of $($file.Chmod.FileName) set to $($file.Chmod.FilePermissions)"
            Log_ToSplunk -Message "Permissions of $($file.Chmod.FileName) set to $($file.Chmod.FilePermissions)" -Type "Log" -Status "Informational"
        }
        else{
            #Write-Host "Setting permissions of $($file.Chmod.FileName) failed: $($file.Chmod.Error)"
            Log_ToSplunk -Message "Setting permissions of $($file.Chmod.FileName) failed: $($file.Chmod.Error)" -Type "Log" -Status "Informational"
        }
    }
    else{
        #Write-Host "Permissions of $($file.Destination) kept with their defaults"
        Log_ToSplunk -Message "Permissions of $($file.Destination) kept with their defaults" -Type "Log" -Status "Informational"
    }
 
    if ($file.Touch -ne $Null){
        if ($file.Touch.Error -eq $Null){
            #Write-Host "Timestamp of $($file.Touch.FileName) set to $($file.Touch.LastWriteTime)"
            Log_ToSplunk -Message "Timestamp of $($file.Touch.FileName) set to $($file.Touch.LastWriteTime)" -Type "Log" -Status "Informational"
        }
        else{
            #Write-Host "Setting timestamp of $($file.Touch.FileName) failed: $($file.Touch.Error)"
            Log_ToSplunk -Message "Setting timestamp of $($file.Touch.FileName) failed: $($file.Touch.Error)" -Type "Log" -Status "Informational"
        }
    }
    else{
        # This should never happen during "local to remote" synchronization
        #Write-Host "Timestamp of $($file.Destination) kept with its default (current time)"
        Log_ToSplunk -Message "Timestamp of $($file.Destination) kept with its default (current time)" -Type "Log" -Status "Informational"
    }
}
 
# Main script
 
try{
    $session = New-Object WinSCP.Session
    try{
        # Will continuously report progress of synchronization
        $session.add_FileTransferred( { FileTransferred($_) } )
        # Connect
        $session.Open($sessionOptions)
        # Synchronize files
        $synchronizationResult = $session.SynchronizeDirectories(
            [WinSCP.SynchronizationMode]::Remote, $LocalDir, $RemoteDir, $False)
        # Throw on any error
        $synchronizationResult.Check()
    }
    finally{
        # Disconnect, clean up
        $session.Dispose()
    }
    Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
    exit 0
}
catch{
    Write-Host "Error: $($_.Exception.Message)"
    Log_ToSplunk -Message "Script Ending Error: $($_.Exception.Message)" -Type "End" -Status "Informational"
    exit 1
}