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
    Filter-Computerlist.ps1

.DESCRIPTION
    Builds a filtered list of Active Directory computers, classifying retail store computers by UFO_NUMBER pattern.

.FUNCTIONALITY
    Filters and classifies AD computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#$computerlist = Get-Content$computerlist = Get-Content "\\SERVER\SHARE\...\cleanthese_20200730.txt"
$computerlist += (Get-ADComputer -Filter "ObjectClass -like 'computer'" -SearchBase "DC=DOMAIN,DC=com").name
$output = "\\SERVER\SHARE\...\ADComputerObjects"
if(Test-Path $output){Remove-Item $output -Force}
mkdir $output -Force
$computerlist | ForEach-Object{
    [string]$computer = $_
    Write-Host $computer -ForegroundColor White -BackgroundColor Blue
    #Identify retail store computers
    $storeNum = $computer.Substring(0,4)
    if ([regex]$($storeNum) -match "^[1-3,5,8]\d\d\d$")
    {
        Write-Host "$computer IS a store-level retail system" -ForegroundColor Black -BackgroundColor Green
        $role = $computer.Substring(4,2)
        switch($role)
        {
            "co"{$computer | Out-File "$output\core.txt" -Append ascii}
            "sl"{$computer | Out-File "$output\slc.txt" -Append ascii}
            "st"{$computer | Out-File "$output\st.txt" -Append ascii}
            "s2"{$computer | Out-File "$output\st.txt" -Append ascii}
            "s3"{$computer | Out-File "$output\st.txt" -Append ascii}
            "js"{$computer | Out-File "$output\st.txt" -Append ascii}
            "w0"{$computer | Out-File "$output\st.txt" -Append ascii}
            "re"{$computer | Out-File "$output\reg.txt" -Append ascii}
            "ta"{$computer | Out-File "$output\tag.txt" -Append ascii}
            "dc"{$computer | Out-File "$output\dc.txt" -Append ascii}
            "dv"{$computer | Out-File "$output\dvr.txt" -Append ascii}
            default{$computer | Out-File "$output\unassigned.txt" -Append ascii}
        }
    }
    elseif(!([regex]$($storeNum) -match "^[1-3,5,8]\d\d\d$"))
    {
        Write-Host "$computer is NOT a retail system" -ForegroundColor White -BackgroundColor Blue
        $computer | Out-File "$output\CORP.txt" -Append ascii
    }
    else 
    {
        $computer | Out-File "$output\unassigned.txt" -Append ascii
    }
}
