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
    Get-FileCount.ps1

.DESCRIPTION
    Counts files by extension (including custom log and info extensions) under a server share.

.FUNCTIONALITY
    Counts files by extension on a share.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#$parentdir = "C:\"
#$parentdir = \\SERVER\SHARE\*
#$files = Get-ChildItem $parentdir -Recurse -File 

$files = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse
$swl = $files | Where-Object{[regex]$_.Extension -match "domainwasted_log"}
$swi = $files | Where-Object{[regex]$_.Extension -match "domainwasted_info"}
$swo = $files | Where-Object{[regex]$_.Extension -match "domainwasted$"}
$allc = $files.Count
$swoc = $swo.Count
$swlc = $swl.Count
$swic = $swi.Count

$swop = “{0:P2}” -f ($swoc/$allc)
$swlp = “{0:P2}” -f ($swlc/$allc)
$swip = “{0:P2}” -f ($swic/$allc)

Write-Host "Hostname: $env:COMPUTERNAME`n" -ForegroundColor White
Write-Host "domainwasted" -ForegroundColor White -BackgroundColor Blue
Write-Host "COUNT: $swoc`nPERCENTAGE: $swop`n"
Write-Host "domainwasted_log"-ForegroundColor White -BackgroundColor Blue
Write-Host "COUNT: $swlc `nPERCENTAGE: $swlp`n"
Write-Host "domainwasted_info"-ForegroundColor White -BackgroundColor Blue
Write-Host "COUNT: $swic `nPERCENTAGE: $swip`n"
