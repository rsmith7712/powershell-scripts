# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
   Tool-NetworkCreateShortcut.ps1

.SYNOPSIS
    Create desktop shortcut with PowerShell

.FUNCTIONALITY

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts - Tool-Network Create Shortcut
#>

$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut("$Env:Public\Desktop\Google.com.lnk")
$Shortcut.TargetPath = "https://www.google.com"
$Shortcut.IconLocation = "shell32.dll,43"
$Shortcut.Save()