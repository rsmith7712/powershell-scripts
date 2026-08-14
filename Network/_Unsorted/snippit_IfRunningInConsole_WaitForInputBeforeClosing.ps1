# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    snippit_IfRunningInConsole_WaitForInputBeforeClosing.ps1

.DESCRIPTION
    Snippet that pauses for a keypress before closing when run in the console host.

.FUNCTIONALITY
    Pauses for input in the console host.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


#If running in the console, wait for input before closing
if($Host.Name -eq "ConsoleHost"){
    Write-Host "Press any key to continue..."
    $Host.UI.RawUI.FlushInputBuffer() #Make sure buffered input doesn't "press a key" and skip the ReadKey()
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
    }