# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Richard Smith

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
    fGet-HostnameList.ps1

.DESCRIPTION
    Generates store workstation hostnames from a UFO_NUMBER and checks each host's online status.

.FUNCTIONALITY
    Builds and pings a store's hostname list.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


Function Get-Computers($storeNum)
{
    $num = 0
    do
    {
        $num++
        [string]$SWComputer = "$storeNum`W0$num"
        #[string]$SWComputer = $storeNum + "tag" + $num

        Write-Host "[STATUS] : Checking the online status for Hostname: '$SWComputer'."

        $test = Test-Connection -Count 2 $SWComputer -Quiet

        Write-Host $test.ToString()

        if (!($test))
        {
            Write-Host "[SUCCESS] : New hostname: '$SWComputer' will be used as the new computer hostname" -ForegroundColor Green
            $newName = $SWComputer
            return $newName
        }
            Else
            {
                Write-Host "[WARNING] : $SWComputer is already in use. Checking the next incremental value." -ForegroundColor Yellow
            }
    }             
    until
    (
        $num -gt 11
    )
    if ($num -gt 11)
    {
        return 0
    }
}#=========================================[End Function]==========================================
$newName = Get-Computers -storeNum "2009"
if ($newname -eq 0)
{
    $output = "[ERROR] : The script was unable to acquire a hostname within the parameters established. No changes were made to the system."
}
    else
    {
        $output = "[SUCCESS] : The script successfully acquired '$newName'. Attempting to rename system to $newName."
    }
Write-Host $output -ForegroundColor Cyan