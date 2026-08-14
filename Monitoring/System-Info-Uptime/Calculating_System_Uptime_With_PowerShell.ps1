# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Calculating_System_Uptime_With_PowerShell.ps1

.DESCRIPTION
    		What we want to do, specifically, is:
    			- Get today's date.
    			- Get the system boot time.
    			- Perform subtraction (today's date â€“ boot time) to obtain the elapsed uptime.
    			- Present the result in a user-friendly way.
    			- Optionally (but desirable) have the results appear every time we start a Windows PowerShell session.

.FUNCTIONALITY
    		What we want to do, specifically, is:
    			- Get today's date.
    			- Get the system boot time.
    			- Perform subtraction (today's date â€“ boot time) to obtain the elapsed uptime.
    			- Present the result in a user-friendly way.
    			- Optionally (but desirable) have the results appear every time we start a Windows PowerShell session.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

New-Item â€“Path $profile â€“Type file -Force

Set-ExecutionPolicy â€“ExecutionPolicy RemoteSigned

notepad $profile

<#
Paste the following into the Notepad session and save:


Set-Location C:\
$console = $host.UI.RawUI
$console.WindowTitle = "Pirate's PowerShell Console"
$console.BackgroundColor = "Gray"
$console.ForegroundColor = "Black"

$buffer = $console.BufferSize
$buffer.Width = 80
$buffer.Height = 5000
$console.BufferSize = $buffer

$size = $console.WindowSize
$size.Width = 80
$size.Height = 100
$console.WindowSize = $size

New-Item alias:np -value "C:\Windows\System32\notepad.exe"
New-Item alias:st -value "C:\Program Files\Sublime Text 3\sublime_text.exe"

function Get-Uptime
{
	$os = Get-WmiObject win32_operatingsystem
	$uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
	$Display = "Uptime: " + $Uptime.Days + " days, " + $Uptime.Hours + " hours, " + $Uptime.Minutes + " minutes"
	Write-Output $Display
}

Clear-Host
Get-Uptime

#>