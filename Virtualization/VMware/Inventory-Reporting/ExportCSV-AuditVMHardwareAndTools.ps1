<#
.NAME
    ExportCSV-AuditVMHardwareAndTools.ps1

.SUMMARY
    AUDITING VIRTUAL MACHINE HARDWARE AND TOOLS

.PURPOSE
    The VM estate that I manage is large: there are more
    than 20 different clusters and over 300 hosts of
    varying ages and hardware levels – as a consequence
    there are various different versions of ESX and ESXi
    running. Upgrading the hosts is somewhat akin to
    painting the Forth Bridge, a never-ending task. So
    keeping the thousands of VMs at the correct hardware
    and VMtools versions can be a bit of a losing battle.

    What if I want a report showing me all the VM names,
    Hardware Version, VMtools Status, Tools Version Status
    and Tools Version

.AUTHOR
    Creator:    Sam McGeown
    Updated:    ITAdmin

.AUTHOR-URL
    https://www.definit.co.uk/authors/sam-mcgeown/

.URL - Initial Source
    https://www.definit.co.uk/2013/06/powercli-basics-auditing-virtual-machine-hardware-and-tools-using-powercli/
#>

<#
The very last thing to add to the pipeline is to be able
to analyze this data correctly, I need to have it in a
format I can mange – output onto the screen is not so
easy! For this we can use the Export-CSV command which
will dump the contents into a CSV file that we can
manipulate in Excel or another spreadsheet app. The
arguments are a simply the file name we want to export
to, and “-NoType” which just formats it better for Excel.
The final query looks like this:
#>

Import-Module VMware.PowerCLI
#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction $false
Connect-VIServer -Server SERVER.example.com -Protocol https

Get-VM | Get-View | Select-Object Name,@{Name="Hardware Version"; Expression={$_.Config.Version}},@{Name="Tools Status"; Expression={$_.Guest.ToolsStatus}},@{Name="Tools Version Status"; Expression={$_.Guest.ToolsVersionStatus}},@{Name="Tools Version"; Expression={$_.Guest.ToolsVersion}} | Export-CSV c:\temp\Report-AuditVMHardwareAndTools.csv -NoTypeInformation
