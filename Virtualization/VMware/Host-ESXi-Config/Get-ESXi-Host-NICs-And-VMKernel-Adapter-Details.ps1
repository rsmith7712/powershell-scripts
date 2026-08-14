<#
.NAME
    Get-ESXi-Host-NICs-And-VMKernel-Adapter-Details.ps1
.PURPOSE
    Generate a custom report via VMware PowerCLI console session
.NOTES
    Add vCenter connection with authentication
    Add single and multiple targeting
    Add user options menu
    Add check for C:\Temp folder; If not there, create it
    Add export results to CSV
.INITIAL SOURCE URL
https://arabitnetwork.com/2018/07/31/for-vmware-admins-day-to-day-useful-powercli-commands-scripts/
#>

# Import PowerCLI module, Ignore Certificate Errors, and connect to VSphere servers
Import-Module VMware.PowerCLI
#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction $false
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

Get-VMHostNetworkAdapter |`
Select-Object VMhost, Name, IP |`
Format-Table -Autosize
