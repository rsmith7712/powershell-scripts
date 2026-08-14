<#
.NAME
    OnScreen-ListAllSupportedHardwareVersions.ps1

.PURPOSE
    Get a list of all supported virtual hardware versions via powerCLI

.AUTHOR
    Creator:    LucFullenwarth, LucD
    Updated:    ITAdmin

.AUTHOR-URL
    https://communities.vmware.com/t5/user/viewprofilepage/user-id/4651633 
    https://communities.vmware.com/t5/user/viewprofilepage/user-id/256147 

.URL - Initial Source
    https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/How-to-get-a-list-of-all-supported-virtual-hardware-versions-via/td-p/523121 
#>
# Import PowerCLI module, Ignore Certificate Errors, and connect to VSphere servers
Import-Module VMware.PowerCLI
#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction $false
Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

function Get-VMHostVHardwareCapability {
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl]$VMHost
    )
    process {
        foreach ($VMHostItem in $VMHost) {
            [PSCustomObject]@{
                Name = $VMHostItem.Name
                VHardwareCapability = switch ([int]$VMHostItem.ExtensionData.Config.Product.Build) {
                    ###Release numbers can be found here: https://kb.vmware.com/s/article/2143832
                    ###Hardware versions can be found here: https://kb.vmware.com/s/article/2007240
                    #ESXi 7.0 U3
                    { $PSItem -ge 18644231} { 'ESXi 7.0 U3 (Supported VMX: 4, 7, 8, 9, 10, 11, 13, 14, 15, 17, 18, 19)' }
                    #ESXi 7.0 U2
                    { $PSItem -ge 17630552 -and $PSItem -lt 18644231 } { 'ESXi 7.0 U2 (Supported VMX: 4, 7, 8, 9, 10, 11, 13, 14, 15, 17, 18, 19)' }
                    #ESXi 7.0 U1
                    { $PSItem -ge 16850804 -and $PSItem -lt 17630552 } { 'ESXi 7.0 U1 (Supported VMX: 4, 7, 8, 9, 10, 11, 13, 14, 15, 17, 18, 19)' }
                    #ESXi 7.0 GE
                    { $PSItem -ge 15843807 -and $PSItem -lt 16850804 } { 'ESXi 7.0 GE (Supported VMX: 4, 7, 8, 9, 10, 11, 13, 14, 15, 17, 18, 19)' }
                    #ESXi 6.7 U2
                    { $PSItem -ge 13006603 -and $PSItem -lt 15843807 } { 'ESXi 6.7 U2 (Supported VMX: 4, 7, 8, 9, 10, 11, 13, 14, 15)' }
                    #ESXi 6.7
                    { $PSItem -ge 8169922 -and $PSItem -lt 13006603 } { 'ESXi 6.7 (Supported VMX: 4, 7, 8, 9, 10, 11, 13, 14)' }
                    #ESXi 6.5
                    { $PSItem -ge 4564106 -and $PSItem -lt 8169922 } { 'ESXi 6.5 (Supported VMX: 4, 7, 8, 9, 10, 11, 13)' }
                    #ESXi 6.0
                    { $PSItem -ge 2494585 -and $PSItem -lt 4564106 } { 'ESXi 6.0 (Supported VMX: 4, 7, 8, 9, 10, 11)' }
                    #ESXi 5.5
                    { $PSItem -ge 1331820 -and $PSItem -lt 2494585 } { 'ESXi 5.5 (Supported VMX: 4, 7, 8, 9, 10)' }
                    #ESXi 5.1
                    { $PSItem -ge 799733 -and $PSItem -lt 1331820 } { 'ESXi 5.1 (Supported VMX: 4, 7, 8, 9)' }
                    #ESXi 5.0
                    { $PSItem -ge 469512 -and $PSItem -lt 799733 } { 'ESXi 5.0 (Supported VMX: 4, 7, 8)' }
                    #ESXi/ESX 4.x
                    { $PSItem -ge 164009 -and $PSItem -lt 469512 } { 'ESXi 4.x (Supported VMX: 4, 7)' }
                    Default { 'Unknow ESXi version' }
                }
            }
        }
    }
}
Get-VMHost | Get-VMHostVHardwareCapability | Sort-Object Count -Descending
