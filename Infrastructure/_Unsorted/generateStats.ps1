# LEGAL
<# LICENSE
    MIT License, Copyright 2024 Richard Smith

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
    generateStats.ps1.txt

.DESCRIPTION
    Provides a progress-display helper function used while generating statistics over a collection.

.FUNCTIONALITY
    Progress-display helper for stats generation.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


function Show-ProgressV3 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,
        [string]$Activity = "Processing items"
    )

        [int]$TotItems = $Input.Count
        [int]$Count = 0

        $Input|foreach {
            $_
            $Count++
            [int]$percentComplete = ($Count/$TotItems* 100)
            Write-Progress -Activity $Activity -PercentComplete $percentComplete -Status ("Working - " + $percentComplete + "%") -CurrentOperation (""+$Count+"/"+$TotItems+" - "+$_.Name)
        }
}

$count = 0
$Visio = New-Object -ComObject Visio.Application

(Get-ChildItem -Recurse -Include @("*.vss", "*.vssx")) | Show-ProgressV3 | Foreach-Object {
    $doc = $Visio.Documents.OpenEx($_.FullName, 192)
    $count += $doc.Masters.Count
    $doc.close()

    Start-Sleep 1
}

$Visio.Quit()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Visio) | Out-Null

Write-Host "Old template files:" (Get-ChildItem -Recurse -Include "*.vss").Count
Write-Host "New template files:" (Get-ChildItem -Recurse -Include "*.vssx").Count
Write-Host "Total visio stencils:" $count
