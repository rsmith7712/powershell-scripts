﻿# LEGAL
<# LICENSE
    MIT License, Copyright 2024 Richard Smith

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
	Query-ADComputers-for-NetAdapter-CN-MAC.ps1

.DESCRIPTION
	Script queries Active Directory for all computer objects, then attempts to
	connect to each computer to retrieve the MAC address of each network adapter.
	The results are compiled into a dataset and exported to a CSV file.

.FUNCTIONALITY
	- Get list of all computers in AD
	- For each computer, test whether it is online
	- If online, get MAC addresses of machine and add to dataset
	- If not online, log an empty entry for the computer in the dataset
	- Export dataset to CSV file

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# get list of all computers in AD
$computers = get-adcomputer -filter *

# create object to hold all data
$master = @()

# iterate through each computer
foreach ($computer in $computers)
{
	# test whether computer is online
	write-host "Getting MAC Addresses for computer: $($computer.Name)"
	$test = Test-Connection -Computername $computer.Name -BufferSize 16 -Count 1 -Quiet
	if ($test -eq "true")
	{
		# get mac addresses of machine
		$macAddresses = & getmac.exe /s $computer.Name | out-string
		# split reponse into array of lines
		$arr = $macAddresses -split "`n"


	# data starts on $arr[3] - loop through remaining lines
		for ($i=3; $i -le $arr.Count; $i++)
		{
			# get only the mac address (first 17 characters)
			if ($arr[$i].Length -ge 16)
			{ 
				# create object for computer and mac address
				$obj = New-Object PSObject -Property @{
					Computer = $computer.Name
					MACAddress = $arr[$i].Substring(0,17) 
				}
				# add object to master array
				$master += $obj
			}
		}		
	}
	else
	{
		# Unable to connect to the computer - log an empty entry
		$obj = New-Object PSObject -Property @{
					Computer = $computer.Name
					MACAddress = "Computer was not online or there was a problem with the connection" 
				}
		# add object to master array
		$master += $obj
	}
}
# export dataset to csv
$master | export-csv "c:\results\output.csv" -NoTypeInformation