# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    FolderSize.ps1

.DESCRIPTION
    Reports the size of each subfolder under a user-documents share and exports the results to CSV.

.FUNCTIONALITY
    Reports share subfolder sizes to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$startFolder = "\\SERVER\SHARE"
$resultsloc = "c:\temp\foldersize.csv"
remove-item $resultsloc -force
$count = 1
$objFSO = New-Object -com  Scripting.FileSystemObject 
$colItems = (Get-ChildItem $startFolder| Where-Object {$_.PSIsContainer -eq $True} | Sort-Object)
foreach ($i in $colItems)
    {
        [string]$size = ($objFSO.GetFolder("$startFolder\$i").Size)
        $count = $count + 1
        $usersize = $usersize + "`n" + $size + "," + $i + "," + "=A$count/1073741824" + "," + "GBs"
    }
$usersize | Out-File $resultsloc