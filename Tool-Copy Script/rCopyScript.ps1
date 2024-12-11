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
    Simple script uses robocopy to copy all contents of directory
        to another directory including empty folders. Created
        script to assist people who do not regularly utilize Rc.

.FUNCTIONALITY
    $sourceDir: The path to the source directory you want to copy.
    $destinationDir: The path to the destination directory where 
        you want to copy the files and folders.
    /E: This switch tells Robocopy to copy all subdirectories,
        including empty ones. 
    /ZB: This switch uses restartable mode, which is more resilient
        to network interruptions.
    /LOG:C:\Logs\RobocopyLog.txt: This switch creates a log file
        named "RobocopyLog.txt" in the "C:\Logs" directory,
        recording the details of the copy operation. 

How to run the script:
    Save the code as a .ps1 file (e.g., CopyScript.ps1).
    -eplace the placeholder paths with your actual source and destination directories.
    -Open PowerShell as an administrator.
    -Navigate to the directory where you saved the script.
    -Run the script by typing .\CopyScript.ps1 and pressing Enter.

#>

$sourceDir = "C:\SourceDirectory"
$destinationDir = "D:\DestinationDirectory"

robocopy $sourceDir $destinationDir /E /ZB /LOG:C:\Logs\RobocopyLog.txt