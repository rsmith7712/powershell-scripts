# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Sitaram Pamarthi [http)://techibee.com]

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
   Get-DNSServers.ps1

.SYNOPSIS
    - Get the DNS servers list of each IP enabled network connection

.FUNCTIONALITY
    Computer Name(s) from which you want to query the DNS server details.
	If this parameter is not used, the the script gets the DNS servers
	from local computer network adapaters.
        
    .Example 1
        Get-DNSServers.ps1 -ComputerName MYTESTPC21
		Get the DNS servers information from a remote computer MYTESTPC21.

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

[cmdletbinding()]
param (
	[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	[string[]] $ComputerName = $env:computername
)

begin {}
process {
	foreach($Computer in $ComputerName) {
		Write-Verbose "Working on $Computer"
		if(Test-Connection -ComputerName $Computer -Count 1 -ea 0) {
			
			try {
				$Networks = Get-WmiObject -Class Win32_NetworkAdapterConfiguration `
							-Filter IPEnabled=TRUE `
							-ComputerName $Computer `
							-ErrorAction Stop
			} catch {
				Write-Verbose "Failed to Query $Computer. Error details: $_"
				continue
			}
			foreach($Network in $Networks) {
				$DNSServers = $Network.DNSServerSearchOrder
				$NetworkName = $Network.Description
				If(!$DNSServers) {
					$PrimaryDNSServer = "Notset"
					$SecondaryDNSServer = "Notset"
				} elseif($DNSServers.count -eq 1) {
					$PrimaryDNSServer = $DNSServers[0]
					$SecondaryDNSServer = "Notset"
				} else {
					$PrimaryDNSServer = $DNSServers[0]
					$SecondaryDNSServer = $DNSServers[1]
				}
				If($network.DHCPEnabled) {
					$IsDHCPEnabled = $true
				}
				
				$OutputObj  = New-Object -Type PSObject
				$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()
				$OutputObj | Add-Member -MemberType NoteProperty -Name PrimaryDNSServers -Value $PrimaryDNSServer
				$OutputObj | Add-Member -MemberType NoteProperty -Name SecondaryDNSServers -Value $SecondaryDNSServer
				$OutputObj | Add-Member -MemberType NoteProperty -Name IsDHCPEnabled -Value $IsDHCPEnabled
				$OutputObj | Add-Member -MemberType NoteProperty -Name NetworkName -Value $NetworkName
				$OutputObj
				
			}
		} else {
			Write-Verbose "$Computer not reachable"
		}
	}
}

end {}