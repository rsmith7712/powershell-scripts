<#
.NAME
    Get-OS-Version-Information.ps1

.URL - Resource
https://adamtheautomator.com/powercli-tutorial/

#>

Import-Module VMware.PowerCLI
#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction $false
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

Get-VM |`
Sort-Object -Property Name |`
Get-View -Property @("Name", "Config.GuestFullName", "Guest.GuestFullName") |`
Select -Property Name, @{N="Configured OS";E={$_.Config.GuestFullName}}, @{N="Running OS";E={$_.Guest.GuestFullName}} |`
Export-CSV C:\Report-ESXi-VM-OS-Information.csv -NoTypeInformation
