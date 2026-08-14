<#
.TITLE
	VmwareHostBuildCheck.ps1

.SUMMARY
	Script to check whether a host is in the build level you want

.REQUIREMENTS
	Windows - Need to be logged in to vCenter with PowerCLI via PowerShell Admin session

.AUTHOR
	Sahan Fernando // 2020-05-02 Created
    IT Admin  // 2021-09-23 Modified for environment

.URL- Script:
https://scriptigator.com/2020/05/02/how-to-check-esx-host-version-and-build-number-with-powercli/

.URL - VMware Build numbers and version of ESXi / ESX (KB 2143832)
https://kb.vmware.com/s/article/2143832
#>

## VARIABLES
#$vcenter = "<vCenter_name>"
#$cluster_name = "<cluster_name>"
$expected_build = 17630552 #VMware ESXi 7.0 Update 2, Rel. 2021-03-09

## MAIN
#Connect to VMware vCenter Instance
Connect-VIServer -Server  "srvvcenterp.example.com" -Protocol https

#Query for ESXi host version and build info, then compare build number to approved build number
Get-VMHost | Select @{Label = "Host"; Expression = {$_.Name}} , `
    @{Label = "ESXi Version"; Expression = {$_.version}}, `
    @{Label = "ESXi Build" ; Expression = {$_.build}} , `
    @{Label = "Build Match" ; Expression = {if($_.build -eq $expected_build){"Yes"} else{"No"}}} | `
    Export-csv C:\temp\Report-VmwareHostBuildCheck-host-n-build-info.csv

## Future Addition
#Query clusters for ESXi host version and build info, then compare build number to approved build number
#Get-Cluster $cluster_name | Get-VMHost | Select @{Label = "Host"; Expression = {$_.Name}} , @{Label = "ESX Version"; Expression = {$_.version}}, @{Label = "ESX Build" ; Expression = {$_.build}} , @{Label = "Build Match" ; Expression = {if($_.build -eq $expected_build){"Yes"} else{"No"}}} | Export-csv c:\temp\vmware-host-version-n-build-info.csv
