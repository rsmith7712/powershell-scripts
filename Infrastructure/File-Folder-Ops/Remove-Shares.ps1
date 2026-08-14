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
    Remove-Shares.ps1

.DESCRIPTION
    Deletes named SMB shares on a computer via WMI, reporting the result per share.

.FUNCTIONALITY
    Deletes named shares on a computer.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Remove-Shares($computer,$shares)
{
    $shares | foreach{
        if(Test-Path "\\$computer\$_")
        {
            $returnvalue = (Get-WmiObject -Class Win32_Share -Filter "Name= '$_'" -ComputerName $computer).Delete().ReturnValue
            if($returnvalue -eq 0)
            {
                $output = "SUCCESS: Share '\\$computer\$_' successfully deleted. Return Code:$returnvalue"
            }
                else
                {
                    $output = "ERROR: Unable to delete Share '\\$computer\$_'.  Return Code:$returnvalue"
                }
        }
            else
            {
                $output = "WARNING: Unable to delete Share '\\$computer\$_'. Share not found."
            }
        Write-Host $output -ForegroundColor Yellow
    }
}#---------[END Function:Remove-Shares]---------

# //////// ---[SCRIPT BEGINS]--- \\\\\\\\

$shares = @("DOCS","REPORTS")
$store = Read-Host "Enter UFO_NUMBER"
$computer = $store + "ST"
#$computer = $env:COMPUTERNAME
Write-Host "Target computer:$computer" -ForegroundColor Cyan
Remove-Shares -computer $computer -shares $shares

# \\\\\\\\\ ---[SCRIPT ENDS]--- /////////
