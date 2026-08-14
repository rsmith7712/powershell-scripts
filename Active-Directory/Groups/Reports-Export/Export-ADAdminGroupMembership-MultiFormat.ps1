#Requires -Modules ActiveDirectory
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
    Export-ADAdminGroupMembership-MultiFormat.ps1

.SYNOPSIS
    Exports membership for selected Active Directory administrative groups to TXT,
    CSV, and optional PDF.

.DESCRIPTION
    Queries one or more Active Directory groups, writes a timestamped text report
    for human-readable review, writes a structured CSV report for sorting and
    analysis, and can optionally convert the text report to PDF by automating
    Microsoft Word.

    This public-safe sample uses placeholder paths and configurable group names
    so it can be shared publicly without exposing internal environment details.

    .NOTES
        Replace placeholder values with environment-appropriate values before
        production use.

    .PARAMETER OutputDirectory
        Directory where report files will be written.

    .PARAMETER OutputBaseName
        Base name used for generated output files.

    .PARAMETER GroupNames
        One or more Active Directory group names to query.

    .PARAMETER ConvertToPdf
        If specified, attempts to convert the generated text file to PDF using
        Microsoft Word. Microsoft Word must be installed on the system running
        the script.

    .PARAMETER KeepTextFile
        If specified together with -ConvertToPdf, retains the source text file
        after PDF creation.

    .EXAMPLE
        .\Export-ADAdminGroupMembership-MultiFormat.ps1

    .EXAMPLE
        .\Export-ADAdminGroupMembership-MultiFormat.ps1 -OutputDirectory 'C:\Reports' -GroupNames 'Domain Admins','Enterprise Admins' -ConvertToPdf

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory = 'C:\Reports',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputBaseName = 'ADAdminGroupMembership',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$GroupNames = @(
        'Domain Admins',
        'Enterprise Admins',
        'Schema Admins'
    ),

    [Parameter()]
    [switch]$ConvertToPdf,

    [Parameter()]
    [switch]$KeepTextFile
)

Import-Module ActiveDirectory -ErrorAction Stop

function Convert-TextFileToPdf {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$Path
    )

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $pdfPath = [System.IO.Path]::ChangeExtension($resolvedPath, '.pdf')

    $word = $null
    $document = $null

    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $document = $word.Documents.Open($resolvedPath)
        $document.SaveAs([ref]$pdfPath, [ref]17)
        return $pdfPath
    }
    finally {
        if ($document) {
            $document.Close()
        }
        if ($word) {
            $word.Quit()
        }
    }
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$textPath = Join-Path -Path $OutputDirectory -ChildPath ("{0}-{1}.txt" -f $OutputBaseName, $timestamp)
$csvPath = Join-Path -Path $OutputDirectory -ChildPath ("{0}-{1}.csv" -f $OutputBaseName, $timestamp)
$runDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$header = @(
    "ACTIVE DIRECTORY ADMINISTRATIVE GROUP MEMBERSHIP - REPORT GENERATED ON $runDate",
    "",
    "Groups queried: $($GroupNames -join ', ')"
)
$header | Set-Content -Path $textPath -Encoding UTF8

$csvRows = foreach ($groupName in $GroupNames) {
    Add-Content -Path $textPath -Value "`r`n=== $groupName ==="
    Add-Content -Path $textPath -Value "Get-ADGroupMember '$groupName' -Recursive | Select-Object SamAccountName, Name, ObjectClass"

    try {
        $members = Get-ADGroupMember -Identity $groupName -Recursive -ErrorAction Stop |
            Select-Object SamAccountName, Name, ObjectClass

        if ($members) {
            foreach ($member in $members) {
                Add-Content -Path $textPath -Value ("{0}`t{1}`t{2}" -f $member.SamAccountName, $member.Name, $member.ObjectClass)

                [PSCustomObject]@{
                    ReportGeneratedOn = $runDate
                    GroupName          = $groupName
                    SamAccountName     = $member.SamAccountName
                    DisplayName        = $member.Name
                    ObjectClass        = $member.ObjectClass
                }
            }
        }
        else {
            Add-Content -Path $textPath -Value '[No members returned]'

            [PSCustomObject]@{
                ReportGeneratedOn = $runDate
                GroupName          = $groupName
                SamAccountName     = $null
                DisplayName        = $null
                ObjectClass        = $null
            }
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Add-Content -Path $textPath -Value "[Error querying group '$groupName': $errorMessage]"

        [PSCustomObject]@{
            ReportGeneratedOn = $runDate
            GroupName          = $groupName
            SamAccountName     = $null
            DisplayName        = "ERROR: $errorMessage"
            ObjectClass        = $null
        }
    }
}

$csvRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "Text report created: $textPath"
Write-Host "CSV report created:  $csvPath"

if ($ConvertToPdf) {
    $pdfPath = Convert-TextFileToPdf -Path $textPath
    Write-Host "PDF created:        $pdfPath"

    if (-not $KeepTextFile -and (Test-Path -LiteralPath $pdfPath)) {
        Remove-Item -LiteralPath $textPath -Force
        Write-Host "Text report removed after successful PDF conversion."
    }
}
