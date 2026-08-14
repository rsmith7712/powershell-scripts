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
    Get-MDBFiles_Schtask_Corp_v4_OU_CopyItem.ps1

.DESCRIPTION
    		A description of the file.

.FUNCTIONALITY
    		A description of the file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

FUNCTION Logging($pingerror, $Computer){
	$loggingFile = "\\SERVER\SHARE\...\log_Get-MDBFiles_Cumulative_DomainServersOU.txt";
	$timestamp = (Get-Date).ToString();
	$logstring = "Computer: {0}" -f $Computer;
	"$timestamp - $logstring" | out-file $loggingFile -Append;
	
	if ($pingerror -eq $false){ Write-Host "$timestamp - $logstring" -foregroundcolor Green; }
	else{ Write-Host "$timestamp - $logstring" -foregroundcolor Red; }
	return $null;
}

FUNCTION OU_Query{
	## If previous report exists, remove it
	$Computers = "\\SERVER\SHARE\...\list_OU_DomainServers.txt"
	if (Test-Path $Computers) { rm $Computers }
	## Query specified OU, create text file, and populate it with DNSHostname's of OU contents
	$ou = "OU=Domain Servers,DC=Domain,DC=com"
	$Computers = Get-ADComputer -Filter '*' -SearchBase $ou
	$Computers | Foreach { $_.DNSHostName } | Out-File -Filepath "\\SERVER\SHARE\...\list_OU_DomainServers.txt"
}
OU_Query

# Wait 1-minute for text file population
Write-Host "Waiting 15-seconds for text file population";
sleep -Seconds 15
Write-Host;

# Sets the Server Inclusion List from a Text File just created from the FUNCTION OU_Query
$ServerList = Get-Content "\\SERVER\SHARE\...\list_OU_DomainServers.txt"

## If previous End Report CSV exists, Remove it
$outfile = "\\SERVER\SHARE\...\Get-MDBFiles_Cumulative_DomainServersOU.CSV"
if (Test-Path $outfile) { rm $outfile }


ForEach ($Server in $ServerList){
	
	# Test connection to target server
	Write-Host "Testing connection to target server";
	If (Test-Connection -CN $Server -Quiet){
		# Create install folder - \\$Server\c$\scripts
		Invoke-Command â€“ComputerName $Server â€“scriptblock { New-Item -Path "C:\scripts" -ItemType directory â€“Force }
		
		# Copy file 
		Write-Host "Before Copy-Item section";
		Copy-Item -Path \\SERVER\SHARE\...\Get-MDBFiles.ps1 -Destination \\$Server\c$\...\Get-MDBFiles.ps1 -Force
		Write-Host "After Copy-Item section";
		Write-Host;
		
		# Create Scheduled Task on Each Remote System 
		Write-Host "Before Scheduled Task Creation";
		SCHTASKS /CREATE /s $Server /TN "Get-MDBFiles" /SC "ONCE" /RU "SYSTEM" /ST "23:59" /TR "Powershell -executionpolicy bypass -file C:\temp\Get-MDBFiles.ps1" /F
		SCHTASKS /RUN /s $Server /TN "Get-MDBFiles"
		Write-Host "After Scheduled Task Creation";
		Write-Host;
		
		# Wait 5-minutes after Scheduled Task is created and runs to populate the text file on the local host
		Write-Host "Waiting 5-minutes for host to discover local MDB's and populate text file";
		sleep -Seconds 300
		Write-Host;
		
		# Create variable to reference the discovery text file on local hosts
		$results = type \\$Server\c$\...\mdbfiles.txt
		
		# Call discovery file variable and copy contents to CSV 
		Write-Host "Copying local host results to network CSV";
		Add-Content -Path $outfile -Value $results
		Write-Host;
		
		# Dump progress to logging function 
		Logging $False $Server;
	}
}
