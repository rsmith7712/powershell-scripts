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
    Get-MDBFiles_Schtask_Corp_v2_Robocopy.ps1

.DESCRIPTION
    		A description of the file.

.FUNCTIONALITY
    		A description of the file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

## FUNCTION - Logging
function Logging($pingerror, $Computer){
	$loggingFile = "\\SERVER\SHARE\...\log_Get-MDBFiles_Cumulative_corp.txt";
	$timestamp = (Get-Date).ToString();
	$logstring = "Computer: {0}" -f $Computer;
	"$timestamp - $logstring" | out-file $loggingFile -Append;
	
	if ($pingerror -eq $false){
		Write-Host "$timestamp - $logstring" -foregroundcolor Green;
	}
	else{
		Write-Host "$timestamp - $logstring" -foregroundcolor Red;
	}
	return $null;
}

## If previous End Report CSV exists, Remove it, and Create a New one
$outfile = "\\SERVER\SHARE\...\Get-MDBFiles_Cumulative_corp.CSV"
if (Test-Path $outfile) { rm $outfile }

## Set Server Inclusion List from a Text File
$ServerList = Get-Content "\\SERVER\SHARE\...\serverlist_co.txt"

## ForEach Loop - Copy script to target systems and create scheduled task to run once
ForEach ($Server in $ServerList)
{
	# Test connection to target server
	If (Test-Connection -CN $Server -Quiet)
	{
		ROBOCOPY "\\SERVER\SHARE\...\scripts" "\\$Server\c$\scripts" "Get-MDBFiles.ps1" /z /r:1 /w:1
		SCHTASKS /CREATE /s $Server /TN "Get-MDBFiles" /SC "ONCE" /RU "SYSTEM" /ST "23:59" /TR "Powershell -executionpolicy bypass -file C:\temp\Get-MDBFiles.ps1" /F
		SCHTASKS /RUN /s $Server /TN "Get-MDBFiles"
		
		sleep -Seconds 300
		
		$results = type \\$Server\c$\...\mdbfiles.txt
		
		Add-Content -Path $outfile -Value $results
		
		# Dump progress to logging function 
		Logging $False $Server;
	}
}