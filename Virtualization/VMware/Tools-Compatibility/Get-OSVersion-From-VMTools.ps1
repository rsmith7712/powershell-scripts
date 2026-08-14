<#
.NAME
    Get-OSVersion-From-VMTools.ps1

.SUMMARY
    Get guest OS version reported by VMware tools versus configured when VM created or edited.

.DESCRIPTION
    Inventory script to get the OS version that is selected for the VM in edit settings,
    Also output a list of the OS version that VMware tools is reporting to discover
    the ones with wrong OS selected.


    .RESOURCE-URL
    https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/powercli-get-guest-OS-version-reported-by-VMware-tools-versus/td-p/2686309

#>

#Connect to VMware vCenter Instance
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

Get-VM | Sort-Object -Property Name |`
Get-View -Property @("Name", "Config.GuestFullName", "Guest.GuestFullName") |`
Select-Object -Property Name,`
    @{N="Configured OS";E={$_.Config.GuestFullName}},`
    @{N="Running OS";E={$_.Guest.GuestFullName}} |`
Export-Csv "C:\Temp\Report-Get-OSVersion.csv" -NoTypeInformation -UseCulture
