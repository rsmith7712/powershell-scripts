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
    Deploy_fonts.ps1

.DESCRIPTION
    Deploys fonts to target computers, logging per-computer status.

.FUNCTIONALITY
    Deploys fonts to computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format "HH:mm:ss"
$Script:Logfile = "C:\temp\Fontsdeploy.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Computer Name,Status"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}
# ----------------------------------------------------------------------------------------------
# Variables

#$computers = get-content \\SERVER\SHARE\...\TestList.txt
$computers = Read-Host "enter computer name"
#$computers = Get-Content C:\testlist.txt

# ----------------------------------------------------------------------------------------------
# Functions

function deploy-shortcut {
        if (!(test-connection $computer -quiet)) 
        {
            append-log "$computer,Offline"
            continue
        }
        else 
        {
            Copy-Item -path \\SERVER\SHARE\...\Gotham-Black.otf -destination \\$computer\C$\...\Gotham-Black.otf
            Copy-Item -path \\SERVER\SHARE\...\Gotham-Book.otf -destination \\$computer\C$\...\Gotham-Book.otf


            $FONTS = 0x14
            $objShell = New-object -ComObject Shell.Application
            $objFolder = $objShell.Namespaces($FONTS)


        }
    }

# ----------------------------------------------------------------------------------------------
#Start Script

foreach ($computer in $computers) 
    {
    deploy-shortcut
    }