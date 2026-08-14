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
    Get-MDBFiles_Schtask_corp.ps1

.DESCRIPTION
    Deploys the Get-MDBFiles script to corporate servers via robocopy and creates a scheduled task to run it.

.FUNCTIONALITY
    Deploys a scheduled task to inventory MDB files.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

CLS
$computers = Get-Content "\\SERVER\SHARE\...\serverlist_co.txt"
#$computers = Read-Host "Enter Computername"
$outfile = "\\SERVER\SHARE\...\Get-MDBFiles_Cumulative_corp.CSV"
#$outfile = "C:\temp\Get-MDBFiles_Cumulative_corp.CSV"
if(Test-Path $outfile){rm $outfile}


$computers | foreach{
    $computername = $_
    "$computername - creating scheduled task"
       ROBOCOPY "\\SERVER\SHARE\...\scripts" "\\$computername\c$\scripts" "Get-MDBFiles.ps1" /z /r:1 /w:1
	   SCHTASKS /CREATE /s $computername /TN "Get-MDBFiles" /SC "ONCE" /RU "SYSTEM" /ST "23:59" /TR "Powershell -executionpolicy bypass -file C:\temp\Get-MDBFiles.ps1" /F
       SCHTASKS /RUN /s $computername /TN "Get-MDBFiles"
    }
    sleep -Seconds 300


$computers | foreach{
    $computername = $_
    "$computername - copying output"
    type \\$computername\c$\...\mdbfiles.txt | foreach{
    "$computername,$_" | Out-File $outfile -Append ascii
    }
}

