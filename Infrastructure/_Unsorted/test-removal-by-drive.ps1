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
    test-removal-by-drive.ps1

.DESCRIPTION
    Enumerates and (in WhatIf mode) removes wasted files on a server drive, logging via transcript.

.FUNCTIONALITY
    Previews wasted-file cleanup on a drive (WhatIf).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Start-Transcript "C:\Temp\DC17-RDrive-WastedFilesRemoved.txt"
Get-ChildItem -Path \\SERVER\SHARE\* -Include *.domainwasted* -Recurse | ForEach-Object ($_) {Remove-Item $_.FullName -WhatIf}
Stop-Transcript 