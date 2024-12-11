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

.SYNOPSIS
    Below is a PowerShell script that uses Robocopy to copy all
        the contents of a directory to another directory, including
        empty folders. The script includes helpful comments and
        prompts to guide users who are not familiar with Robocopy.

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

.NOTES
2024-12-11:[UPDATE]
    (1) Full rewrite; Added: User input prompt, Source/Destination validation,
        Report success / failure to console, Validate C:\Temp location & 
        create if doesn't exist, Create & write results to a log file.
    (2) The script now starts with a cleared console and hides its code from
        view. It only displays prompts and results to the user.

2024-12-11:[CREATED]
    Request: Simple script uses robocopy to copy all contents of
        directory to another directory including empty folders.
        Created script to assist people who do not regularly utilize Rc.

#>

# Hide script code from the console
$Host.UI.RawUI.WindowTitle = "Robocopy Automation Script"
Clear-Host

# Prompt user for source and destination directories
$source = Read-Host "Enter the full path of the source directory (e.g., C:\\Source)"
$destination = Read-Host "Enter the full path of the destination directory (e.g., D:\\Destination)"

# Set default log file location
$logFolder = "C:\\Temp"
$logFile = Join-Path -Path $logFolder -ChildPath "RobocopyLog.txt"

# Check if the log folder exists, if not create it
if (-not (Test-Path -Path $logFolder)) {
    Write-Host "The log folder '$logFolder' does not exist. Creating it now..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

# Validate that the source directory exists
if (-not (Test-Path -Path $source)) {
    Write-Host "Error: The source directory '$source' does not exist." -ForegroundColor Red
    Add-Content -Path $logFile -Value "[ERROR] The source directory '$source' does not exist."
    exit
}

# Create the destination directory if it doesn't exist
if (-not (Test-Path -Path $destination)) {
    Write-Host "The destination directory '$destination' does not exist. Creating it now..." -ForegroundColor Yellow
    Add-Content -Path $logFile -Value "[INFO] The destination directory '$destination' does not exist. Creating it now..."
    New-Item -ItemType Directory -Path $destination | Out-Null
}

# Define Robocopy options
# /E: Copies all subdirectories, including empty ones
# /Z: Uses restartable mode for network resiliency
# /COPYALL: Copies all file attributes, including permissions
$options = "/E /Z /COPYALL"

# Execute Robocopy
Write-Host "Starting copy process..." -ForegroundColor Green
Add-Content -Path $logFile -Value "[INFO] Starting copy process from '$source' to '$destination'."
$robocopyCommand = "Robocopy `"$source`" `"$destination`" $options /LOG+:`"$logFile`""
Invoke-Expression $robocopyCommand

# Check the exit code to determine success or failure
# 0: No files copied, no failures
# 1: Files copied successfully
# Other: Errors or issues
if ($LASTEXITCODE -eq 0) {
    Write-Host "Robocopy completed successfully. No files needed copying." -ForegroundColor Green
    Add-Content -Path $logFile -Value "[INFO] Robocopy completed successfully. No files needed copying."
}
elseif ($LASTEXITCODE -eq 1) {
    Write-Host "Robocopy completed successfully. Files were copied." -ForegroundColor Green
    Add-Content -Path $logFile -Value "[INFO] Robocopy completed successfully. Files were copied."
}
else {
    Write-Host "Robocopy encountered errors. Exit code: $LASTEXITCODE" -ForegroundColor Red
    Add-Content -Path $logFile -Value "[ERROR] Robocopy encountered errors. Exit code: $LASTEXITCODE."
}

Write-Host "Script execution completed." -ForegroundColor Cyan
Add-Content -Path $logFile -Value "[INFO] Script execution completed."