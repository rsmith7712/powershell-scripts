# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    Get-IPDetails.ps1

.DESCRIPTION
    Reports IP address details for one or more computers.

.FUNCTIONALITY
    Reports computer IP details.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Get-IPDetails.ps1
#
#
# .\Get-IPDetails.ps1 -Computername | ft -AutoSize
#


[cmdletbinding()]
param (
 [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [string[]]$ComputerName = $env:computername
)
 
begin {}
process {
 foreach ($Computer in $ComputerName) {
  if(Test-Connection -ComputerName $Computer -Count 1 -ea 0) {
   try {
    $Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer -EA Stop | ? {$_.IPEnabled}
   } catch {
        Write-Warning "Error occurred while querying $computer."
        Continue
   }
   foreach ($Network in $Networks) {
    $IPAddress  = $Network.IpAddress[0]
    $SubnetMask  = $Network.IPSubnet[0]
    $DefaultGateway = $Network.DefaultIPGateway
    $DNSServers  = $Network.DNSServerSearchOrder
    $WINS1 = $Network.WINSPrimaryServer
    $WINS2 = $Network.WINSSecondaryServer   
    $WINS = @($WINS1,$WINS2)         
    $IsDHCPEnabled = $false
    If($network.DHCPEnabled) {
     $IsDHCPEnabled = $true
    }
    $MACAddress  = $Network.MACAddress
    $OutputObj  = New-Object -Type PSObject
    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()
    $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
    $OutputObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
    $OutputObj | Add-Member -MemberType NoteProperty -Name Gateway -Value ($DefaultGateway -join ",")      
    $OutputObj | Add-Member -MemberType NoteProperty -Name IsDHCPEnabled -Value $IsDHCPEnabled
    $OutputObj | Add-Member -MemberType NoteProperty -Name DNSServers -Value ($DNSServers -join ",")     
    $OutputObj | Add-Member -MemberType NoteProperty -Name WINSServers -Value ($WINS -join ",")        
    $OutputObj | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MACAddress
    $OutputObj
   }
  }
 }
}
 
end {}