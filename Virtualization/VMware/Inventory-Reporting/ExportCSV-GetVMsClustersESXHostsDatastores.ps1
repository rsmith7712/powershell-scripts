<#
.NAME
    Export-CSV-GetVMsClustersESXHostsDatastores.ps1

.SUMMARY
    Get VMs, Clusters, ESX Hosts, Datastores, and Export to CSV

.PURPOSE
    Generate a report of a VMware compute environment (VM’s, Clusters,
    ESX Hosts, and Datastores), and export the output to a CSV file.

.AUTHOR
    Creator:    afokkema
    Updated:    ITAdmin

.AUTHOR-URL
    https://ict-freak.nl/author/afokkema/

.URL - Initial Source
    https://ict-freak.nl/2009/11/17/powercli-one-liner-to-get-vms-clusters-esx-hosts-and-datastores/

#>

Import-Module VMware.PowerCLI
#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction $false
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

Get-VM | Select-Object Name, @{N="Cluster";E={Get-Cluster -VM $_}}, `
@{N="ESX Host";E={Get-VMHost -VM $_}}, `
@{N="Datastore";E={Get-Datastore -VM $_}} | `
Export-Csv C:\Temp\Report-GetVMsClustersHostsDatastores.csv -NoTypeInformation
