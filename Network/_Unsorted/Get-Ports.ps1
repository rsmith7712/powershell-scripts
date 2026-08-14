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
    Get-Ports.ps1

.DESCRIPTION
    Tests TCP port 135 connectivity across distribution-center computers in Active Directory and exports the results to CSV.

.FUNCTIONALITY
    Tests TCP port 135 across AD computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$csv = "\\SERVER\SHARE\...\Get-Ports.csv"
#$computers = get-content "\\SERVER\SHARE\...\corpservers2.txt"
$computers = (Get-ADComputer -Filter "*" -SearchBase "OU=Distribution Center Computers,OU=Store Computers,DC=DOMAIN,DC=com").Name
$computers | 
ForEach-Object{
    $computer = $_
    Try
    {
        $netTest = Test-NetConnection -ComputerName "$($computer).example.com" -port 135 -ErrorAction Stop | 
        Select-Object -Property Computername,RemoteAddress,RemotePort,TcpTestSucceeded 
        Write-Host $computer $netTest.TcpTestSucceeded -ForegroundColor White -BackgroundColor Blue
        $netTest | Export-Csv -Path $csv -NoTypeInformation -Append -Force
    }
        catch
        {
            Write-Host "[WARNING] :$($_), The following exception occurred: $($_.Exception.Message)." -ForegroundColor White -BackgroundColor Red
        }
    $ErrorActionPreference = "SilentlyContinue"
    #$output += $test
}
#$output | Export-Csv -Path "\\SERVER\SHARE\...\Get-Ports.csv"
Invoke-Item $csv