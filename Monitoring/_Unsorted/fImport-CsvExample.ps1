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
    fImport-CsvExample.ps1

.DESCRIPTION
    Reads the latest infection-detection CSV and tests TCP port 135 in parallel across the listed computers (workflow).

.FUNCTIONALITY
    Parallel-tests a TCP port across computers from a CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Workflow Test-NetworkPort
{
    $reports = "\\SERVER\SHARE\...\Asset Inventory\infected_detection"
    $csv = (Get-ChildItem $reports -File | Select-Object -Last 1).FullName
    $computers = (Import-Csv -Path $csv | Where-Object{$_.Status -match "Wasted" -and $_.Computer -notmatch "-ads-"}).Computer
    #$computers 
    ForEach -parallel ($computer in $computers){
        try
        {
            #Write-Output "[STATUS] : $computer`: Checking TCP port 135 listening status."
            $rpcCheck = (Test-NetConnection -ComputerName "$($computer)" -port 135 -ErrorAction Stop).TcpTestSucceeded
            if($rpcCheck)
            {
                Write-Output "[STATUS] : $computer`: Confirmed host listening over TCP 135. Continuing operation."
            }
                else
                {
                    Write-Output "[STATUS] : $computer`: Host is NOT listening over TCP 135. Skipping host."
                }
        }
            catch
            {
                "[WARNING] :$($_), The following exception occurred: $($_.Exception.Message)."
            }
        $ErrorActionPreference = "SilentlyContinue"
    }
}
####################[SCRIPT STARTS]#####################
Test-NetworkPort
Write-Output "[STATUS] : Script Completion"
Exit
#####################[SCRIPT ENDS]######################