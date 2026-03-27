<#
.LICENSE
    MIT License, Copyright 2024 Richard Smith

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

.NAME
    rCopyScript.ps1

.DESCRIPTION
    PowerShell script to copy all contents of a directory to another
    directory using Robocopy, and includes prompts for source
    and destination paths.

.FUNCTIONALITY
    This script guides the user step-by-step:
    -Prompts the user for the source and destination directories.
    -Validates that the source directory exists.
    -Creates the destination directory if it doesn't exist.
    -Runs Robocopy with options to include empty folders and restartable mode.
    -Checks and informs the user of the success or failure of the operation.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# Hide script code from the console
$Host.UI.RawUI.WindowTitle = "Robocopy Automation Script"
Clear-Host

# Prompt user for source and destination directories
$source = Read-Host "Enter the full path of the source directory (e.g., C:\\Source)"
$destination = Read-Host "Enter the full path of the destination directory (e.g., D:\\Destination)"

# Ensure paths are properly quoted to handle spaces and special characters
$source = $source.Trim('"')
$destination = $destination.Trim('"')

# Set default log file location
$logFolder = "C:\\Temp"
$logFile = Join-Path -Path $logFolder -ChildPath "RobocopyLog.txt"

# Check if the log folder exists, if not create it
try {
    if (-not (Test-Path -Path $logFolder)) {
        Write-Host "The log folder '$logFolder' does not exist. Creating it now..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $logFolder | Out-Null
    }
}
catch {
    Write-Host "Error: Failed to create log folder '$logFolder'. Ensure you have proper permissions." -ForegroundColor Red
    exit
}

# Validate that the source directory exists
try {
    if (-not (Test-Path -Path $source)) {
        Write-Host "Error: The source directory '$source' does not exist." -ForegroundColor Red
        Add-Content -Path $logFile -Value "[ERROR] The source directory '$source' does not exist."
        exit
    }
}
catch {
    Write-Host "Error: Invalid characters in source directory path." -ForegroundColor Red
    Add-Content -Path $logFile -Value "[ERROR] Invalid characters in source directory path."
    exit
}

# Create the destination directory if it doesn't exist
try {
    if (-not (Test-Path -Path $destination)) {
        Write-Host "The destination directory '$destination' does not exist. Creating it now..." -ForegroundColor Yellow
        Add-Content -Path $logFile -Value "[INFO] The destination directory '$destination' does not exist. Creating it now..."
        New-Item -ItemType Directory -Path $destination | Out-Null
    }
}
catch {
    Write-Host "Error: Failed to create destination directory. Ensure you have proper permissions." -ForegroundColor Red
    Add-Content -Path $logFile -Value "[ERROR] Failed to create destination directory."
    exit
}

# Test write permissions on the destination
try {
    $testFile = Join-Path -Path $destination -ChildPath "TestWritePermissions.txt"
    Add-Content -Path $testFile -Value "Test" -Force
    Remove-Item -Path $testFile -Force
}
catch {
    Write-Host "Error: No write permissions for the destination directory '$destination'." -ForegroundColor Red
    Add-Content -Path $logFile -Value "[ERROR] No write permissions for the destination directory '$destination'."
    exit
}

# Define Robocopy options
# /S: Copies subdirectories. This option automatically excludes empty directories.
# /E: Copies subdirectories. This option automatically includes empty directories.
# /Z: Copies files in restartable mode. In restartable mode, should a file copy
#       be interrupted, robocopy can pick up where it left off rather than
#       recopying the entire file.
# /B: Copies files in backup mode. In backup mode, robocopy overrides file and
#       folder permission settings (ACLs), which might otherwise block access.
# /ZB: Copies files in restartable mode. If file access is denied, switches
#       to backup mode.
# /COPYALL: Copies all file attributes, including permissions
$options = "/E /ZB /COPYALL"

# Execute Robocopy
Write-Host "Starting copy process..." -ForegroundColor Green
Add-Content -Path $logFile -Value "[INFO] Starting copy process from '$source' to '$destination'."
$robocopyCommand = "Robocopy `"$source`" `"$destination`" $options /LOG+:`"$logFile`""
Invoke-Expression $robocopyCommand

# Check the exit code to determine success or failure
switch ($LASTEXITCODE) {
    0 {
        Write-Host "Robocopy completed successfully. No files needed copying." -ForegroundColor Green
        Add-Content -Path $logFile -Value "[INFO] Robocopy completed successfully. No files needed copying."
    }
    1 {
        Write-Host "Robocopy completed successfully. Files were copied." -ForegroundColor Green
        Add-Content -Path $logFile -Value "[INFO] Robocopy completed successfully. Files were copied."
    }
    2..7 {
        Write-Host "Robocopy completed with warnings. Exit code: $LASTEXITCODE" -ForegroundColor Yellow
        Add-Content -Path $logFile -Value "[WARNING] Robocopy completed with warnings. Exit code: $LASTEXITCODE."
    }
    8..15 {
        Write-Host "Robocopy encountered errors. Exit code: $LASTEXITCODE" -ForegroundColor Red
        Add-Content -Path $logFile -Value "[ERROR] Robocopy encountered errors. Exit code: $LASTEXITCODE."
    }
    16 {
        Write-Host "Robocopy encountered a serious error. Exit code: 16" -ForegroundColor Red
        Add-Content -Path $logFile -Value "[CRITICAL] Robocopy encountered a serious error. Exit code: 16."
    }
    default {
        Write-Host "Unexpected exit code: $LASTEXITCODE" -ForegroundColor Red
        Add-Content -Path $logFile -Value "[ERROR] Unexpected exit code: $LASTEXITCODE."
    }
}

Write-Host "Script execution completed." -ForegroundColor Cyan
Add-Content -Path $logFile -Value "[INFO] Script execution completed."