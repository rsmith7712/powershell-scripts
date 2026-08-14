# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Get-FileVersion.ps1

.SYNOPSIS
Get-FileVersion
  
.NOTES
  Version:        1.0
  Author:         user10
  Creation Date:  08/13/2018
  Purpose/Change: Initial Script Development

.HISTORY
  Version:        1.0
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Get-FileVersion

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Functions
#################################

Function Get-FileVersion
{
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $output,

        [parameter(Mandatory=$true,
        Position=1)]
        $computers,

        [parameter(Mandatory=$true,
        Position=2)]
        $file        
    )

     if(Test-Path $output){Remove-Item $output}
    "Computer,Status,Cornerstone_Version" | Out-File -FilePath $output -Encoding ascii -Append

    foreach ($computer in $computers){

        if(Test-Connection -ComputerName $computer -Count 1 -Quiet){
        
        Try
        {
            $ErrorActionPreference = "Stop"
            $fp = "\\$computer\$file"
            $csver = (Get-Item $fp).VersionInfo.FileVersion

            Write-Host "$computer | Online | $csver" -ForegroundColor Cyan
            "$computer,Online,$csver" | Out-File -FilePath $output -Encoding ascii -Append
        }
            Catch
            {
                Write-Host "$computer | Online | $($_.Exception.Message)" -ForegroundColor Red
                "$computer,Online,$($_.Exception.Message)" | Out-File -FilePath $output -Encoding ascii -Append
            }

            Finally
            {
                $ErrorActionPreference = "SilentlyContinue"
            }
        }
        else{
            Write-Host "$computer | Offline | N/A" -ForegroundColor Yellow
            "$computer,Offline,N/A" | Out-File -FilePath $output -Encoding ascii -Append
        }
    }
}

# Script Starts
#################################

$computers = @()
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store additional computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name
$computers += (Get-ADComputer -Filter * -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com" | where-object {$_.name.substring(0,1) -ne "3"}).name

#$computers = Get-Content "C:\temp\computers.txt"

$file = "c$\Program Files (x86)\Cornerstone OnDemand Inc\Cornerstone OnDemand Network Player\CyberU.NetworkPlayer.exe"

$output = "c:\temp\CornerStoneVersions.csv"

Get-FileVersion -output $output -computers $computers -file $file

# Script Ends
#################################




