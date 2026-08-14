# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    fDetect-MMP.ps1

.DESCRIPTION
    Detects whether the DartS MMP readme is present on the store's CORE computer.

.FUNCTIONALITY
    Detects store MMP status.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Detect-MMP
{
    $store = ($env:COMPUTERNAME).Substring(0,4)
    $core = $store + "CORE"
    $coreStatus = Test-NetConnection $core -InformationLevel Quiet
    switch($coreStatus)
    {
        $true 
        {
            $file = "\\$core\DartS\Readme.MMP.txt"
            $mmpStatus = Test-Path -Path $file
            switch($mmpStatus)
            {
                $true
                {
                    Write-Host "MMP" -ForegroundColor White -BackgroundColor Blue
                }
                $false
                {
                    Write-Host "Darts" -ForegroundColor White -BackgroundColor Magenta
                }
            }
        }
        $false
        {
            $output = "$core is offline. Unable to continue. Exiting script..."
            Write-Host $output -ForegroundColor White -BackgroundColor Red
            Start-Sleep -Seconds 5
            Exit 1
        }
    }
}

