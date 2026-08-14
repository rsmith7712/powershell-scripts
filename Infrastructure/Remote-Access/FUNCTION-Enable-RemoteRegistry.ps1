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
    FUNCTION-Enable-RemoteRegistry.ps1

.Synopsis
    This will enable the remote registry service on local or remote computers.
    For updated help and examples refer to -Online version.
.DESCRIPTION
    This will enable the remote registry service on local or remote computers.
    For updated help and examples refer to -Online version.
.NOTES  
    Name: Enable-RemoteRegistry
    Author: The Sysadmin Channel
    Version: 1.0
    DateCreated: 2018-Jun-21
    DateUpdated: 2018-Jun-21
.LINK
    https://thesysadminchannel.com/remotely-enable-remoteregistry-service-powershell -
.EXAMPLE
    For updated help and examples refer to -Online version.

.FUNCTIONALITY
    This will enable the remote registry service on local or remote computers.
        For updated help and examples refer to -Online version.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Enable-RemoteRegistry {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [string[]]  $ComputerName = $env:COMPUTERNAME
    )
    BEGIN {}
    PROCESS {
        Foreach ($Computer in $ComputerName) {
            try {
                $RemoteRegistry = Get-CimInstance -Class Win32_Service -ComputerName $Computer -Filter 'Name = "RemoteRegistry"' -ErrorAction Stop
                if ($RemoteRegistry.State -eq 'Running') {
                    Write-Output "$Computer is already Enabled"
                }
                if ($RemoteRegistry.StartMode -eq 'Disabled') {
                    Set-Service -Name RemoteRegistry -ComputerName $Computer -StartupType Manual -ErrorAction Stop
                    Write-Output "$Computer : Remote Registry has been Enabled"
                }
                if ($RemoteRegistry.State -eq 'Stopped') {
                    Start-Service -InputObject (Get-Service -Name RemoteRegistry -ComputerName $Computer) -ErrorAction Stop
                    Write-Output "$Computer : Remote Registry has been Started"
                }
            } catch {
                $ErrorMessage = $Computer + " Error: " + $_.Exception.Message
            }
        }
    }
    END {}
}