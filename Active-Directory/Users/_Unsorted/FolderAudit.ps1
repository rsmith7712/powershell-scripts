<#
LICENSE
    MIT License

    Copyright (c) 2020 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
#>

<#
.Name
    FolderAudit.ps1

.SYNOPSIS
    Audits folders in a target directory and optionally purges stale folders.

.DESCRIPTION
    This script scans subfolders beneath a target path and records metadata such as:
      - Folder name
      - Inferred owner(s) from ACL entries
      - Last accessed time
      - Last written time
      - Optional folder size
      - Optional purge status

    Results are exported to a CSV file.

    When -PurgeStaleFolders is used, the script can remove folders that meet all of
    the following conditions:
      1. No valid owner was inferred from the ACL
      2. Last access time is older than the configured stale threshold
      3. Last write time is older than the configured stale threshold

    If deletion fails due to permissions, the script can optionally take ownership
    and grant a placeholder administrative group full control before retrying.

    Review and test carefully before enabling purge behavior in production.

.NOTES
    Public-safe placeholders are intentionally used in this version.
    Replace the following values before production use:
      - DefaultPath
      - AdminGroup
      - OutputPath

    LastAccessTime may not be reliable in every Windows environment.

    .PARAMETER GetSize
        Calculates recursive folder size.

    .PARAMETER UsePromptForPath
        Prompts for a target path instead of using the DefaultPath value.

    .PARAMETER PurgeStaleFolders
        Removes folders that match the stale-folder criteria.

    .PARAMETER DefaultPath
        Default root path containing the folders to inspect.

    .PARAMETER OutputPath
        CSV output path.

    .PARAMETER ErrorLogPath
        Path used for deletion error logging.

    .PARAMETER AdminGroup
        Administrative group granted access if ownership recovery is needed.

    .PARAMETER StaleYears
        Number of years used to determine whether a folder is stale.

    .EXAMPLE
        .\FolderAudit.ps1

    .EXAMPLE
        .\FolderAudit.ps1 -GetSize

    .EXAMPLE
        .\FolderAudit.ps1 -UsePromptForPath -GetSize

    .EXAMPLE
        .\FolderAudit.ps1 -PurgeStaleFolders -WhatIf

    .EXAMPLE
        .\FolderAudit.ps1 -PurgeStaleFolders -Confirm

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

    Author:
    Original: Kevin Mangus
    Modified: Richard Smith
 
    ByteConversion: https://stackoverflow.com/a/24617034
    Test Dir - C:\Users\Guest\Documents

#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param (
    [switch]$GetSize,
    [switch]$UsePromptForPath,
    [switch]$PurgeStaleFolders,
    [string]$DefaultPath = '\\FileServer\Shares\UserHomeDirs',
    [string]$OutputPath = "$env:USERPROFILE\Documents\results.csv",
    [string]$ErrorLogPath = "$env:USERPROFILE\Documents\remove_item_errors.txt",
    [string]$AdminGroup = 'EXAMPLE\Domain Admins',
    [ValidateRange(1, 25)]
    [int]$StaleYears = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-FolderSize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Folder
    )

    $byteCount = (Get-ChildItem -Path $Folder -Recurse -File -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum

    if (-not $byteCount) {
        return '0 Bytes'
    }

    switch ([math]::Truncate([math]::Log($byteCount, 1024))) {
        0 { return "$byteCount Bytes" }
        1 { return ('{0:N2} KB' -f ($byteCount / 1KB)) }
        2 { return ('{0:N2} MB' -f ($byteCount / 1MB)) }
        3 { return ('{0:N2} GB' -f ($byteCount / 1GB)) }
        4 { return ('{0:N2} TB' -f ($byteCount / 1TB)) }
        default { return ('{0:N2} PB' -f ($byteCount / 1PB)) }
    }
}

function Grant-FolderAccess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$FolderName,

        [Parameter(Mandatory)]
        [string]$GroupName
    )

    & takeown.exe /f $FolderName /A /R /D Y | Out-Null
    & icacls.exe $FolderName /grant "$GroupName:(F)" /C /T /Q | Out-Null
}

function Get-InferredOwners {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Folder
    )

    $ignoredPrincipals = @('SYSTEM', 'Users', 'Administrators', 'Domain Admins')

    $owners = (Get-Acl -Path $Folder).Access |
        Select-Object -ExpandProperty IdentityReference -Unique |
        ForEach-Object {
            $value = $_.ToString()
            if ($value -match '\\') {
                ($value -split '\\', 2)[1]
            }
            else {
                $value
            }
        } |
        Where-Object { $_ -and ($_ -notin $ignoredPrincipals) } |
        ForEach-Object { $_.Trim().ToLowerInvariant() } |
        Where-Object { $_ }

    return @($owners)
}

# Clean up prior output if present.
Remove-Item -Path $OutputPath -ErrorAction SilentlyContinue

if ($UsePromptForPath) {
    $inputPath = Read-Host 'Input path to directory'
    $targetDirectories = Get-ChildItem -Path $inputPath -Directory | Select-Object -ExpandProperty FullName
}
else {
    $targetDirectories = Get-ChildItem -Path $DefaultPath -Directory | Select-Object -ExpandProperty FullName
}

$totalDirectoryCount = @($targetDirectories).Count
$directoryIndex = 0
$staleCutoff = (Get-Date).AddYears(-$StaleYears)

foreach ($folder in $targetDirectories) {
    $directoryIndex++

    $percentComplete = if ($totalDirectoryCount -gt 0) {
        [int](($directoryIndex / $totalDirectoryCount) * 100)
    }
    else {
        100
    }

    Write-Progress -Activity 'Scanning directories' -Status "Working on $folder" -PercentComplete $percentComplete

    $item = Get-Item -Path $folder
    $folderOwners = Get-InferredOwners -Folder $folder
    $lastAccessed = $item.LastAccessTime
    $lastWritten = $item.LastWriteTime
    $purgeStatus = ''
    $size = $null

    if ($GetSize) {
        $size = Get-FolderSize -Folder $folder
    }

    if ($PurgeStaleFolders) {
        $hasNoInferredOwner = ($folderOwners.Count -eq 0)
        $isStaleByAccess = ($lastAccessed -lt $staleCutoff)
        $isStaleByWrite = ($lastWritten -lt $staleCutoff)

        if ($hasNoInferredOwner -and $isStaleByAccess -and $isStaleByWrite) {
            if ($PSCmdlet.ShouldProcess($folder, 'Remove stale folder')) {
                try {
                    Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                }
                catch {
                    Grant-FolderAccess -FolderName $folder -GroupName $AdminGroup

                    try {
                        Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                    }
                    catch {
                        "$(Get-Date -Format s) | Error: $($_.Exception.Message) | Item: $($_.Exception.ItemName)" |
                            Out-File -FilePath $ErrorLogPath -Append -Encoding utf8
                    }
                }
            }
        }

        if (-not (Test-Path -Path $folder)) {
            $purgeStatus = 'Purged'
        }
    }

    $result = [PSCustomObject]@{
        Folder_Name    = $item.Name
        User           = ($folderOwners -join ', ')
        Last_Accessed  = $lastAccessed
        Last_Written   = $lastWritten
        Size           = $size
        Folders_Purged = $purgeStatus
    }

    $result | Export-Csv -Path $OutputPath -Append -NoTypeInformation
}

Write-Progress -Activity 'Scanning directories' -Completed
Write-Host "Completed. Results written to: $OutputPath"
if ($PurgeStaleFolders) {
    Write-Host "Deletion errors, if any, were logged to: $ErrorLogPath"
}
