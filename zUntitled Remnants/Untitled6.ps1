# LEGAL
<# LICENSE
    MIT License, Copyright 2025 Richard Smith

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
    Untitled6.ps1

.DESCRIPTION
    This script is designed to collect MAC Address information from local and remote
    computers using PowerShell. The script includes multiple solutions for retrieving
    MAC Address information, and can be modified to include additional functionality
    as needed.

.FUNCTIONALITY


.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

## Access is Denied for Get-WmiObject ##

$discovery = Get-ADComputer -Filter *
$results = New-Object System.Collections.ArrayList

ForEach($computer in $discovery){

    $allAdapters = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" -ComputerName $computer.Name

    $nics = $allAdapters | Where-Object{$_.DNSDomain -like "*.symetrix.com"}

    ForEach($adapter in $nics){

        $temp = New-Object PSCustomObject -Property @{ComputerName="$($computer.Name)";Adapter="$($adapter.Description)";IPAddress="$($adapter.IPAddress)";MAC="$($adapter.MACAddress)"}
        $results.Add($temp) | Out-Null
    }
}
$results | Select-Object ComputerName,Adapter,MAC,IPAddress | Export-Csv C:\Results\Untitled6.csv -NoTypeInformation