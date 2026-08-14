<#
.NAME
    ExportCSV-ListVMsByTheirHosts.ps1

.SUMMARY
    List VMs by their hosts; Export to csv

.PURPOSE
    Simple script to that will output to a CSV
    a list of VMs and which host they reside on

.AUTHOR-URL
   https://communities.vmware.com/t5/user/viewprofilepage/user-id/762209

.URL - Initial Source
   https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/PowerCLI-Script-to-list-VMs-by-their-hosts/td-p/2147965

#>

#Connect to VMware vCenter Instance
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

Get-VM | Select-Object Name, VMHost | Export-Csv C:\Temp\Report-ListVMsByTheirHosts.csv -NoTypeInformation -UseCulture
