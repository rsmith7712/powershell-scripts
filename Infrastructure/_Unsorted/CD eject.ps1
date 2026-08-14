# LEGAL
<# LICENSE
    MIT License, Copyright 2015 Richard Smith

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
    CD eject.ps1

.DESCRIPTION
    Ejects or closes the optical-drive tray via the IMAPI COM interface.

.FUNCTIONALITY
    Ejects or closes the CD/DVD tray.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

[CmdletBinding()] 
param( 
[switch]$Eject, 
[switch]$Close 
) 
try { 
    $Diskmaster = New-Object -ComObject IMAPI2.MsftDiscMaster2 
    $DiskRecorder = New-Object -ComObject IMAPI2.MsftDiscRecorder2 
    $DiskRecorder.InitializeDiscRecorder($DiskMaster) 
    if ($Eject) { 
        $DiskRecorder.EjectMedia() 
    } elseif($Close) { 
        $DiskRecorder.EjectMedia() 
    } 
} catch { 
    Write-Error "Failed to operate the disk. Details : $_" 
} 