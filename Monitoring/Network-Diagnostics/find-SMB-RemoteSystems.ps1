# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
    find-SMB-RemoteSystems.ps1

.DESCRIPTION
    Reports the SMBv1/SMBv2 protocol configuration across all reachable Active Directory computers and exports to CSV.

.FUNCTIONALITY
    Reports SMB protocol config across AD computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$b4={Get-SMBServerConfiguration | Select-Object EnableSMB1Protocol,EnableSMB2Protocol,pscomputername}

ForEach ($COMPUTER in (Get-ADComputer -Filter '*' | Select-Object -ExpandProperty Name))
    {if(!(Test-Connection -ComputerName $computer -BufferSize 16 -Count 1 -ea 0 -quiet))
        {write-host "cannot reach $computer" -f red}
    else{
        Invoke-Command -ComputerName $computer -ScriptBlock $b4
        }
        $b4 | Export-Csv C:\temp\report-SMB-results.csv -NoTypeInformation -UseCulture
    }
