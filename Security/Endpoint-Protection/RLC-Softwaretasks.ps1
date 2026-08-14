   # LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    RLC-Softwaretasks.ps1

.DESCRIPTION
    		Uninstalls bit9, MNAC and HIPS.

.FUNCTIONALITY
    		Uninstalls bit9, MNAC and HIPS.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#--------------------FUNCTIONS--------------------------

function uninstall-bit9 
{
	Set-Location "C:\Program Files (x86)\bit9\parity agent"
	    .\dascli.exe password Bit9C0rpUninstal!
		    Start-Sleep -Seconds 02
        .\dascli.exe tamperprotect 0
            Start-Sleep -Seconds 02
        .\dascli.exe disconnect
            Start-Sleep -Seconds 02
        .\dascli.exe seccon 80
            Start-Sleep -Seconds 02
        .\dascli.exe allowuninstall 1
            Start-Sleep -Seconds 02
        Start-Sleep -Seconds 02
	    $guid = (Get-WmiObject -Class Win32_Product -Filter "Name = 'Bit9 Agent'").identifyingnumber
        msiexec /x $guid /qn
        Write-Host "Bit9 Uninstalled"
}

function uninstall-mnac
{
    (Get-WmiObject -Class Win32_product -Filter "Name = 'McAfee Network Access Control Client'").uninstall()
    Write-Host "MNAC Uninstalled"
}

function uninstall-hips
{
    Set-Location "C:\Program Files\McAfee\Host Intrusion Prevention"
    .\ClientControl.exe /stop domaincorphelp
    Start-Sleep -Seconds 10
    (Get-WmiObject -Class Win32_product -Filter "Name = 'McAfee Host Intrusion Prevention'").uninstall()
    Write-Host "HIPS Uninstalled"
}

function install-LANDESKEPSAGENT
{
    Copy-Item \\SERVER\SHARE\LDMSEPSAGENT01_with_status.exe C:\software\LDMSEPSAGENT01_with_status.exe -force
    C:\software\LDMSEPSAGENT01_with_status.exe
}



#-------------------START SCRIPT----------------------------


if (!(Get-WmiObject -Class Win32_Product -Filter "Name = 'Bit9 Agent'")) {Write-Host "Bit9 Not Present"}
else
{
    uninstall-bit9
    Start-Sleep -Seconds 30
}

if (!(Get-WmiObject -Class Win32_product -Filter "Name = 'McAfee Network Access Control Client'")) {Write-Host "MNAC Not Present"}
else
{
    uninstall-mnac
    Start-Sleep -Seconds 30
}


<#
if (!(Get-WmiObject -Class Win32_product -Filter "Name = 'McAfee Host Intrusion Prevention'")) {Write-Host "HIPS Not Present"}
else
{
    uninstall-hips
    Start-Sleep -Seconds 30
}
#>

<#
if (!(Get-WmiObject -Class win32_product -Filter "Name = 'LANDesk(R) Common Base Agent 8'"))
{
    install-LANDESKEPSAGENT
}
else
{
    Write-Host "LANDesk already installed"
}
#>