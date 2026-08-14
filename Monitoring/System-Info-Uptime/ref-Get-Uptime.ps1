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
    ref-Get-Uptime.ps1

.DESCRIPTION
    	A script to determine the time since last boot.

.FUNCTIONALITY
    	This script will reach out to a machine on the network and determine the last Boot time, and will
    	advise the time since last boot.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function Get-Uptime
{
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $True)]
		[Alias('Host')]
		[string[]]$ComputerName = 'localhost'
	)
	BEGIN
	{
		$PSVersion = (Get-Host).Version.Major
	}
	
	PROCESS
	{
		foreach ($computer in $ComputerName)
		{
			try
			{
				$timestring = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer -ErrorAction Stop | `
					Select-Object -ExpandProperty LastBootupTime).split('.')[0]
				
				# The date-time string isn't in a useful format; need to convert it:
				$regex = '^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})'
				if ($timestring -match $regex)
				{
					$time = "$($matches[1])-$($matches[2])-$($matches[3]) $($matches[4]):$($matches[5]):$($matches[6])"
				}
				
				# Convert the new date-time string into a date-time object, then compare:
				$boottime = Get-Date -Date $time
				$LongTimeSinceBoot = (Get-Date) - $boottime
				$TimeSinceBoot = "$($LongTimeSinceBoot.Days.ToString().PadLeft(2, '0')):$($LongTimeSinceBoot.Hours.ToString().PadLeft(2, '0')):$($LongTimeSinceBoot.Minutes.ToString().PadLeft(2, '0'))"
			}
			catch
			{
				# If the system couldn't be queried, set up output
				$boottime = 'Unknown'
				$TimeSinceBoot = 'System Unreachable'
				Write-Warning -Message "Unable to reach $computer`:"
				Write-Warning -Message $_.Exception.Message
			}
			
			if ($PSVersion -gt 2)
			{
				# Use the nice, ordered list in v3 and newer
				$props = [ordered]@{
					'ComputerName' = $computer;
					'LastBootupTime' = $boottime;
					'TimeSinceLastBoot' = $TimeSinceBoot
				}
			}
			else
			{
				# In v2, you get the order the system feels like using
				$props = @{
					'ComputerName' = $computer;
					'LastBootupTime' = $boottime;
					'TimeSinceLastBoot' = $TimeSinceBoot
				}
			}
			
			$obj = New-Object -TypeName PSObject -Property $props
			$obj.PSObject.TypeNames.Insert(0, 'ServiceDeskModule.System.UpTime')
			Write-Output -InputObject $obj
		}
	}
	
	END { }
}

Get-Uptime NMANOFF, user21