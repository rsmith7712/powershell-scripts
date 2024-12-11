


#######################
##                   ##
##    SNIPPIT # 1    ##
##                   ##
#######################

#Out to console - Different format
Get-NetIPConfiguration | 
  Select-Object @{n='IPv4Address';e={$_.IPv4Address[0]}}, 
         @{n='MacAddress'; e={$_.NetAdapter.MacAddress}}

<#
EXAMPLE OUTPUT - TO THE CONSOLE:

Get-NetIPConfiguration


InterfaceAlias       : Ethernet
InterfaceIndex       : 7
InterfaceDescription : Intel(R) Ethernet Connection (4) I219-V
NetProfile.Name      : corp.symetrix.com
IPv4Address          : 192.168.150.176
IPv4DefaultGateway   : 192.168.150.1
DNSServer            : 192.168.100.8
                       192.168.100.9

InterfaceAlias       : Wi-Fi
InterfaceIndex       : 19
InterfaceDescription : Intel(R) Dual Band Wireless-AC 8265
NetAdapter.Status    : Disconnected


#>