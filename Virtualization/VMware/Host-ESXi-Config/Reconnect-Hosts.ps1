$connectSpec = New-Object VMware.Vim.HostConnectSpec
$connectSpec.force = $true
$connectSpec.userName = 'root'
$connectSpec.password = '<password>'

# Loop only needs to update hostname and invoke reconnect
Get-VMHost -state Disconnected | foreach-object {
$vmhost = $_
$connectSpec.hostName = $vmhost.name
$vmhost.extensionData.ReconnectHost_Task($connectSpec,$null)
}