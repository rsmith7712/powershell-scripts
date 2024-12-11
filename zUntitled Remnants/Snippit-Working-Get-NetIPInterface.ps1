


#######################
##                   ##
##    SNIPPIT # 1    ##
##                   ##
#######################

#Out to console
Get-NetIPInterface

<#
EXAMPLE OUTPUT - TO THE CONSOLE:

Get-NetIPInterface

ifIndex InterfaceAlias                  AddressFamily NlMtu(Bytes) InterfaceMetric Dhcp     ConnectionState PolicyStore
------- --------------                  ------------- ------------ --------------- ----     --------------- -----------
4       Local Area Connection* 12       IPv6                  1500              25 Enabled  Disconnected    ActiveStore
13      Local Area Connection* 1        IPv6                  1500              25 Disabled Disconnected    ActiveStore
1       Loopback Pseudo-Interface 1     IPv6            4294967295              75 Disabled Connected       ActiveStore
4       Local Area Connection* 12       IPv4                  1500              25 Disabled Disconnected    ActiveStore
13      Local Area Connection* 1        IPv4                  1500              25 Enabled  Disconnected    ActiveStore
7       Ethernet                        IPv4                  1500              25 Enabled  Connected       ActiveStore
19      Wi-Fi                           IPv4                  1500              25 Enabled  Disconnected    ActiveStore
1       Loopback Pseudo-Interface 1     IPv4                  1500              75 Disabled Connected       ActiveStore

#>