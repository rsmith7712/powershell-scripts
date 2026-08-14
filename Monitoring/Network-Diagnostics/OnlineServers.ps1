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
    OnlineServers.ps1

.DESCRIPTION
    Identifies online Windows web servers (via Quest AD and ping) and inspects the WindowsUpdate.log on each.

.FUNCTIONALITY
    Finds online web servers and checks update logs.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$OnlineServers = @()

Get-QADComputer -SearchRoot 'myexample.com/Web servers' -OSName "Windows*Server*" | %{$PingResult = Get-WmiObject -Query "SELECT * FROM win32_PingStatus WHERE address='$($_.Name)'"
 If ($PingResult.StatusCode -eq 0) {
  $OnlineServers += "$($_.Name)"
	$OnlineServerCount ++
 }
}

$ServerCount = 0
foreach($Server in $OnlineServers) { 
	$FileResult = gwmi cim_datafile -ComputerName $Server -filter "path='\\'" | ? {$_.name -match 'WindowsUpdate.log'}
	if ( $FileResult -ne $null ) {
		Write-Output "$Server"
		##############################
		# DO SOMETHING IN HERE ... ???
		##############################
		$ServerCount ++
	}
}

Write-Output "Total server WindowsUpdate.log copied into \\srv\SharedFolder is $ServerCount out of $OnlineServerCount total online servers."