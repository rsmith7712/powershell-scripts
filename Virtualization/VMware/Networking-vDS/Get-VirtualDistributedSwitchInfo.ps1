<#
.NAME
    Get-VirtualDistributedSwitchInfo.ps1

.SUMMARY
    Gather information of Virtual Distributed Switch (VDS) from vCenter using VMware PowerCLI

.DESCRIPTION
    While working at different clients on their VMware infrastructure,
    I always gather complete inventory of a vCenter infrastructure first
    before doing any changes or designing a solution. This way I get to
    know very quick about the architecture. Here is my script which fetches
    all VDS (Virtual Distributed Switch) from logged in vCenter server. Base
    of the script is PowerCLI command Get-VDSwitch. All the information
    gathered can be easily saved to csv file.

    The inventory collected has information about VDS Name, Datacenter,
    Version, Numer Esx Hosts connected, ESXi Host Members, PortGroup Name,
    Number of Uplink Ports, Uplink PortGroup, Uplink Port Name, Number of
    Ports, MTU, Vendor, Contact Name, Contact Details, Link Discovery Protocol,
    Link Discovery Protocol Operation, vLan Configuration, Notes, Id, Folder,
    CreateTime, Health Check configuration, Over All Status, Multicast Filtering
    Mode, LACP api version, Network Resource Control version, vCenter server name.

.EXAMPLE
    Get-VirtualDistributedSwitchInfo.ps1 | Export-Csv C:\Temp\vdsinfo.csv -NoTypeInformation

.RESOURCE-URL
    http://vcloud-lab.com
    http://vcloud-lab.com/entries/powercli/powercli-gather-complete-virtual-distributed-switch-vds--information-from-vmware-vcenter

.NOTES
    vJanvi      Creator
    ITAdmin      Modifier
#>

#Connect to VMware vCenter Instance
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

$vdSwitch = Get-VDSwitch
foreach ($vds in $vdSwitch)
{
    $esxiList = @()
    $esxiServers = $vds.ExtensionData.Summary.HostMember
    if ($null -ne $esxiServers)
    {
        foreach ($esxi in $esxiServers)
        {
            $esxiList += Get-VMHost -Id $esxi | Select-Object -ExpandProperty Name
        }
    }

    <#
    $vdPortGroupList = @()
    $vdPortGroups = $vds.ExtensionData.Portgroup
    foreach ($vdportgroup in $vdPortGroups)
    {
        $vdPortGroupList += Get-VDPortgroup -Id $vdportgroup | Select-Object -ExpandProperty Name
    }
    #>

    $healthCheckConf1 = $vdSwitch.ExtensionData.Config.HealthCheckConfig[0] | ForEach-Object {"{0}: Enabled={1}, Interval={2}" -f $_.gettype().Name, $_.Enable, $_.Interval}
    $healthCheckConf2 = $vdSwitch.ExtensionData.Config.HealthCheckConfig[1] | ForEach-Object {"{0}: Enabled={1}, Interval={2}" -f $_.gettype().Name, $_.Enable, $_.Interval}

    [PSCustomObject]@{
        Name = $vds.Name
        Datacenter = $vds.Datacenter
        Version = $vds.Version
        NumHosts = $vds.ExtensionData.Summary.NumHosts
        HostMembers = $esxiList -join ', '
        PortGroupName = $vds.ExtensionData.Summary.PortgroupName -join ', '
        NumUplinkPorts = $vds.NumUplinkPorts
        UplinkPortGroup = (Get-VDPortgroup -Id $vds.ExtensionData.Config.UplinkPortgroup).Name
        UplinkPortName = $vds.ExtensionData.Config.UplinkPortPolicy.UplinkPortName -join ', '
        #VDPortGroups = $vdPortGroupList -join ', '
        NumPorts = $vds.NumPorts
        Mtu = $vds.Mtu
        Vendor = $vds.Vendor
        ContactName = $vds.Contactname
        ContactDetails = $vds.ContactDetails
        LinkDiscoveryProtocol = $vds.LinkDiscoveryProtocol
        LinkDiscoveryProtocolOperation = $vds.LinkDiscoveryProtocolOperation
        VlanConfiguration = $vds.VlanConfiguration
        Notes = $vds.Notes
        Id = $vds.Id
        Folder = $vds.Folder
        CreateTime = $vds.ExtensionData.Config.CreateTime
        healthCheckConf1 = $healthCheckConf1
        healthCheckConf2 = $healthCheckConf2
        OverallStatus = $vds.ExtensionData.OverallStatus
        MulticastFilteringMode = $vds.ExtensionData.Config.MulticastFilteringMode
        LacpApiVersion = $vds.ExtensionData.Config.LacpApiVersion
        NetworkResourceControlVersion = $vds.ExtensionData.Config.NetworkResourceControlVersion
        vCenterServer = ([System.Uri]$vds.ExtensionData.Client.ServiceUrl).Host #$vds.Uid.Split('@')[1].Split(':')[0]
    }
}
$vdSwitch | Export-Csv "C:\Temp\Report-VDSwitch-Info.csv" -NoTypeInformation -UseCulture
