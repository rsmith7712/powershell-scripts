# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    Get-NetInfo1.ps1

.DESCRIPTION
    Gathers network information from a list of target computers and exports the results.

.FUNCTIONALITY
    Collects network info from target computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Get-NetInfo.ps1

#Create menu list to choose from Text file or OU


#Import Target List from Text File - Working
$ComputerName = Get-Content C:\Temp\Targets3.txt

#Import Target List from OU - Not working
#$ComputerName = Get-Content "OU=DMZ Servers,OU=Domain Servers,DC=Domain,DC=com"

#Exported results CSV
$Servers_NetInfo ="C:\Temp\DMZ_Target4_NetInfo.csv"
$headers = "ComputerName,OS_Version,IPAddress,SubnetMask,DefaultGateway,IsDHCPEnabled,DNSServers,MACAddress,WINS,Notes"
Add-Content -Path $Servers_NetInfo -Value $headers

#Create an array to store results
#$results = @()

#Create ForEach loop to process Target List
foreach ($Computer in $ComputerName)
{
   Start-Sleep 1
   if(Test-Connection -ComputerName $Computer -Count 1 -ea 0)
   {
       $Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer -EA Stop | Where-Object {$_.IPEnabled}
       
       foreach ($Network in $Networks)
       {
           $OSVersion = Get-WmiObject Win32_Operatingsystem -ComputerName $Computer | Select-Object -expand Caption
           $IPAddress  = $Network.IpAddress[0]
           $SubnetMask  = $Network.IPSubnet[0]
           $DefaultGateway = $Network.DefaultIPGateway
           $DNSServers  = $Network.DNSServerSearchOrder
           $WINS1 = $Network.WINSPrimaryServer
           $WINS2 = $Network.WINSSecondaryServer
           #$WINS = @($WINS1,$WINS2)
           $WINS = "$WINS1,$WINS2"
           $IsDHCPEnabled = $false
           If($network.DHCPEnabled){$IsDHCPEnabled = $true}
           $MACAddress  = $Network.MACAddress
           Add-Content -Path $Servers_NetInfo -Value "$Computer,$OSVersion,$IPAddress,$SubnetMask,$DefaultGateway,$IsDHCPEnabled,$DNSServers,$MACAddress,$WINS"
       }
   }
}

Invoke-Item $Servers_NetInfo