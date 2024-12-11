


#######################
##                   ##
##    SNIPPIT # 1    ##
##                   ##
#######################

#Out to console
Clear-Host
Get-NetAdapter | 
ForEach-Object {
        $PSitem | 
            Select-Object -Property Name, InterfaceDescription, ifIndex, Status, 
            MacAddress,  LinkSpeed,
            @{
                Name       = 'IPAddress'
                Expression = {(Get-NetIPAddress -InterfaceIndex ($PSItem).ifindex).IPv4Address}
            }
} | 
Format-Table -AutoSize

<#
EXAMPLE OUTPUT - TO THE CONSOLE:

Get-NetAdapter

Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
Npcap Loopback Adapter    Npcap Loopback Adapter                       24 Not Present  02-00-4C-4F-4F-50          0 bps
Wi-Fi                     Intel(R) Dual Band Wireless-AC 8265          19 Disconnected C2-23-D0-6C-7A-92          0 bps
Ethernet                  Intel(R) Ethernet Connection (4) I219-V       7 Up           48-2A-E3-13-E8-34         1 Gbps


#>


#######################
##                   ##
##    SNIPPIT # 2    ##
##                   ##
#######################

#Out to file
Clear-Host
Get-NetAdapter | 
ForEach-Object {
        $PSitem | 
            Select-Object -Property Name, InterfaceDescription, ifIndex, Status, 
            MacAddress,  LinkSpeed,
            @{
                Name       = 'IPAddress'
                Expression = {(Get-NetIPAddress -InterfaceIndex ($PSItem).ifindex).IPv4Address}
            }
} | 
Export-Csv -Path 'C:\Results\NicDetails.csv'

<#
EXAMPLE OUTPUT - TO A CSV:

Get-NetAdapter

Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
Npcap Loopback Adapter    Npcap Loopback Adapter                       24 Not Present  02-00-4C-4F-4F-50          0 bps
Wi-Fi                     Intel(R) Dual Band Wireless-AC 8265          19 Disconnected C2-23-D0-6C-7A-92          0 bps
Ethernet                  Intel(R) Ethernet Connection (4) I219-V       7 Up           48-2A-E3-13-E8-34         1 Gbps


#>