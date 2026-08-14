# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    nslookup.ps1

.DESCRIPTION
    		Nslookup & Ping a list of names & IPs using PowerShell

.FUNCTIONALITY
    		Nslookup & Ping a list of names & IPs using PowerShell

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

### This script performs nslookup and ping on all DNS names or IP addresses you list in the text file referenced in $InputFile.
### (One per line.) (Names or IPs can be used!) Outputs to the screen - just copy & paste the screen into Excel to work with results.

$InputFile = 'C:\Users\sysadmin\Desktop\serverlist_co.txt'
$addresses = get-content $InputFile
$reader = New-Object IO.StreamReader $InputFile
while ($reader.ReadLine() -ne $null) { $TotalIPs++ }
write-host    ""
write-Host "Performing nslookup on each address..."
foreach ($address in $addresses)
{
	## Progress bar
	$i++
	$percentdone = (($i / $TotalIPs) * 100)
	$percentdonerounded = "{0:N0}" -f $percentdone
	Write-Progress -Activity "Performing nslookups" -CurrentOperation "Working on IP: $address (IP $i of $TotalIPs)" -Status "$percentdonerounded% complete" -PercentComplete $percentdone
	## End progress bar
	try
	{
		[system.net.dns]::resolve($address) | Select HostName, AddressList
	}
	catch
	{
		Write-host "$address was not found. $_" -ForegroundColor Green
	}
}
write-host    ""
write-Host "Pinging each address..."
foreach ($address in $addresses)
{
	## Progress bar
	$j++
	$percentdone2 = (($j / $TotalIPs) * 100)
	$percentdonerounded2 = "{0:N0}" -f $percentdone2
	Write-Progress -Activity "Performing pings" -CurrentOperation "Pinging IP: $address (IP $j of $TotalIPs)" -Status "$percentdonerounded2% complete" -PercentComplete $percentdone2
	## End progress bar
	if (test-Connection -ComputerName $address -Count 2 -Quiet)
	{
		write-Host "$address responded" -ForegroundColor Green
	}
	else
	{
		Write-Warning "$address does not respond to pings"
	}
}
write-host    ""
write-host "Done!"