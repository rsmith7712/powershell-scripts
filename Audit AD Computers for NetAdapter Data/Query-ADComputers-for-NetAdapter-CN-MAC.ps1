


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