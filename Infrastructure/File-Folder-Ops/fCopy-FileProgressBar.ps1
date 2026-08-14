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
    fCopy-FileProgressBar.ps1

.DESCRIPTION
    Copies a file from source to destination while displaying a progress bar.

.FUNCTIONALITY
    Copies a file with a progress bar.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Copy-FileProgressBar
{
    param
    (
        [string]$from, 
        [string]$to
    )
    $ffile = [io.file]::OpenRead($from)
    $tofile = [io.file]::OpenWrite($to)
    Write-Progress -Activity "Copying file" -status "$from -> $to" -PercentComplete 0
    try 
    {
        [byte[]]$buff = new-object byte[] 4096
        [long]$total = [long]$count = 0
        do
        {
            $count = $ffile.Read($buff, 0, $buff.Length)
            $tofile.Write($buff, 0, $count)
            $total += $count
            if ($total % 1mb -eq 0) 
            {
                Write-Progress -Activity "Copying file" -status "$from -> $to" `
                -PercentComplete ([long]($total/$ffile.Length* 100))
            }
        } 
        while ($count -gt 0)
    }
    finally 
    {
        $ffile.Dispose()
        $tofile.Dispose()
    }
}
$fromPath = "C:\FromOldLenovoLaptop20200217\WinPE_amd64_DomainTkt_v10.2.9.2\media\install.wim"
$toPath = "C:\Users\user2\Downloads\install.wim"
Copy-FileProgressBar -from $fromPath -to $toPath