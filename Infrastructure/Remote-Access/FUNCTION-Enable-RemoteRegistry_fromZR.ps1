#requires -RunAsAdministrator
#requires -Version 3.0
 

<#
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
