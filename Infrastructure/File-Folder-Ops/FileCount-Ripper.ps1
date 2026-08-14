# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Richard Smith

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
    FileCount-Ripper.ps1

.SYNOPSIS
    FileCount-Ripper.ps1

.DESCRIPTION
    Ditch crawl through specified drive / path and identify the following file extensions:
    - .domainwasted
    - .domainwasted_log
    - .domainwasted_temp

    Export results to both .txt and .csv separately for C$ and D$ on:
    - SRV-OPS-FS1 : C$ : Root // D$ : User Shares
    - SRV-OPS-FS2 : C$ : Root // D$ : Dynamics
    - SRV-OPS-FS3 : C$ : Root // D$ : F-Share (i.e. Department Folders)

.EXAMPLE
    .\FileCount-Ripper.ps1

.NOTES
    Version:        v1.0
    Author:         Richard Smith
    Creation Date:  2020-07-11
    Purpose/Change: Initial script creation


.TO-DO
    - Create functions
    - Refine queries
    - Add logging
    - Optimize

.FUNCTIONALITY
    Ditch crawl through specified drive / path and identify the following file extensions:
        - .domainwasted
        - .domainwasted_log
        - .domainwasted_temp

        Export results to both .txt and .csv separately for C$ and D$ on:
        - SRV-OPS-FS1 : C$ : Root // D$ : User Shares
        - SRV-OPS-FS2 : C$ : Root // D$ : Dynamics
        - SRV-OPS-FS3 : C$ : Root // D$ : F-Share (i.e. Department Folders)

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#==========================================[Script Starts]=========================================
$outfile01 = "C:\SASoftware\MI-Scripts\srv-ops-fs3-c.txt"
if(Test-Path $outfile01){Remove-Item $outfile01}

$outfile02 = "C:\SASoftware\MI-Scripts\srv-ops-fs3-c.csv"
if(Test-Path $outfile02){Remove-Item $outfile02}

$outfile03 = "C:\SASoftware\MI-Scripts\srv-ops-fs3-d.txt"
if(Test-Path $outfile03){Remove-Item $outfile03}

$outfile04 = "C:\SASoftware\MI-Scripts\srv-ops-fs3-d.csv"
if(Test-Path $outfile04){Remove-Item $outfile04}

$a = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted
$b = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_info
$c = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_temp

$results1 += $a, $b, $c
$results1 | Out-File -FilePath "C:\SASoftware\MI-Scripts\srv-ops-fs3-c.txt"
#$results1 | Export-Csv "C:\SASoftware\MI-Scripts\srv-ops-fs3-c.csv" -Append -NoTypeInformation

$d = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted
$e = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_info
$f = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_temp

$results2 += $d, $e, $f
$results2 | Out-File -FilePath "C:\SASoftware\MI-Scripts\srv-ops-fs3-d.txt"
#$results2 | Export-Csv "C:\SASoftware\MI-Scripts\srv-ops-fs3-d.csv" -Append -NoTypeInformation

#=========================================[End SRV-OPS-FS3]==========================================

$outfile05 = "C:\SASoftware\MI-Scripts\srv-ops-fs2-c.txt"
if(Test-Path $outfile05){Remove-Item $outfile05}

$outfile06 = "C:\SASoftware\MI-Scripts\srv-ops-fs2-c.csv"
if(Test-Path $outfile06){Remove-Item $outfile06}

$outfile07 = "C:\SASoftware\MI-Scripts\srv-ops-fs2-d.txt"
if(Test-Path $outfile07){Remove-Item $outfile07}

$outfile08 = "C:\SASoftware\MI-Scripts\srv-ops-fs2-d.csv"
if(Test-Path $outfile08){Remove-Item $outfile08}

$g = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted
$h = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_info
$i = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_temp

$results3 += $g, $h, $i
$results3 | Out-File -FilePath "C:\SASoftware\MI-Scripts\srv-ops-fs2-c.txt"
#$results3 | Export-Csv "C:\SASoftware\MI-Scripts\srv-ops-fs2-c.csv" -Append -NoTypeInformation

$j = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted
$k = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_info
$l = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_temp

$results4 += $j, $k, $l
$results4 | Out-File -FilePath "C:\SASoftware\MI-Scripts\srv-ops-fs2-d.txt"
#$results4 | Export-Csv "C:\SASoftware\MI-Scripts\srv-ops-fs2-d.csv" -Append -NoTypeInformation

#=========================================[End SRV-OPS-FS2]==========================================

$outfile09 = "C:\SASoftware\MI-Scripts\srv-ops-fs1-c.txt"
if(Test-Path $outfile09){Remove-Item $outfile09}

$outfile10 = "C:\SASoftware\MI-Scripts\srv-ops-fs1-c.csv"
if(Test-Path $outfile10){Remove-Item $outfile10}

$outfile11 = "C:\SASoftware\MI-Scripts\srv-ops-fs1-d.txt"
if(Test-Path $outfile11){Remove-Item $outfile11}

$outfile12 = "C:\SASoftware\MI-Scripts\srv-ops-fs1-d.csv"
if(Test-Path $outfile12){Remove-Item $outfile12}

$m = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted
$n = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_info
$o = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_temp

$results5 += $m, $n, $o
$results5 | Out-File -FilePath "C:\SASoftware\MI-Scripts\srv-ops-fs1-c.txt"
#$results5 | Export-Csv "C:\SASoftware\MI-Scripts\srv-ops-fs1-c.csv" -Append -NoTypeInformation

$p = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted
$q = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_info
$r = Get-ChildItem -Path \\SERVER\SHARE\* -Recurse -File -Include *.domainwasted_temp

$results6 += $p, $q, $r
$results6 | Out-File -FilePath "C:\SASoftware\MI-Scripts\srv-ops-fs1-d.txt"
#$results6 | Export-Csv "C:\SASoftware\MI-Scripts\srv-ops-fs1-1.csv" -Append -NoTypeInformation

#=========================================[End SRV-OPS-FS1]==========================================
