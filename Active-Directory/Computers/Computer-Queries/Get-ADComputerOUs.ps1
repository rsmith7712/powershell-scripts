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
    Get-ADComputerOUs.ps1

.DESCRIPTION
    Exports each computer's organizational unit and OU name to CSV via a helper function.

.FUNCTIONALITY
    Exports AD computer OU assignments to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Get-AdComputerOu($computer,$outfile)
{
    $ouName = (((Get-ADComputer -Identity $computer).DistinguishedName).split("=")[2]).split(",")[0]
    $ou = ((Get-ADComputer -Identity $computer).DistinguishedName).split(",",2)[1]
    #$parentOu = ((Get-ADComputer -Identity $computer).DistinguishedName).split(",",3)[-1]
    #$parentOuName = ($parentOu.split("=")).split(",")[1]
    $domainComputerObj = [PSCustomObject]@{Computer=$computer; OU=$ou; OuName=$OuName}
    $domainComputerObj | Export-Csv $outfile -Append -NoTypeInformation
    
}

$outfile = "\\SERVER\SHARE\...\AdComputerOus.csv"
if(Test-Path $outfile){rm $outfile}
$inputCsv = "\\SERVER\SHARE\...\cleanthese_20200805.csv"
$inputCsv | Import-Csv | ForEach-Object{
    if($_.Status -match "Wasted")
    {
        [string]$computer = ($_.computer).split(".")[0]
        Write-Host $computer -ForegroundColor Cyan
        Get-AdComputerOu -computer $computer -outfile $outfile
    }
}
Invoke-Item $outfile

