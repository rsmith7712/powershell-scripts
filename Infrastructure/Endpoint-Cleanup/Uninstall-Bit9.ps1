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
    Uninstall-Bit9_v1.ps1

.DESCRIPTION
    		Uninstalls bit9, requires psexec to be installed on local machine. For use removing Bit9 from remote machines.

.FUNCTIONALITY
    		Uninstalls bit9, requires psexec to be installed on local machine. For use removing Bit9 from remote machines.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$ErrorActionPreference = 0
#Credentials
$SPW = ConvertTo-SecureString -AsPlainText -Force -String "<password>"
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "domain\opsadmin", $SPW

#$computers = Get-Content *ENTER FILE PATH HERE*
$computer = Read-Host "Enter Computer Name"

#starts winrm service and sets machine to listen for powershell remote commands. 
function enable-remoting
{
    Get-Service -ComputerName $computer -Name winrm | Start-Service
    psexec \\$computer powershell {winrm quickconfig -q -force}
}

#START SCRIPT

#Checks if bit9 is installed on machine.
$check = (Get-WmiObject -ComputerName $computer -Class Win32_Product -Filter "Name = 'Bit9 Agent'").name
$recheck = (Get-WmiObject -ComputerName $computer -Class Win32_Product -Filter "Name = 'Bit9 Agent'").name
#test connection to machine
if (!(Test-Connection $computer -quiet))
{
    Write-Host "$computer - Offline"
	continue
}
else
{
    #verifying that bit9 is on the machine
    if($check -eq "Bit9 Agent")
    {
        enable-remoting
        #script block that enables bit9 removal on machine
		Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
		    Set-Location "C:\Program Files (x86)\Bit9\Parity Agent"
		    .\Dascli.exe password Bit9C0rpUninstal!
		        Start-Sleep -Seconds 02
            .\dascli.exe tamperprotect 0
                Start-Sleep -Seconds 02
            .\dascli.exe disconnect
                Start-Sleep -Seconds 02
            .\dascli.exe seccon 80
                Start-Sleep -Seconds 02
            .\dascli.exe allowuninstall 1
                Start-Sleep -Seconds 02
            #gets guid of bit9
		    $guid = (Get-WmiObject -Class Win32_Product -Filter "Name = 'Bit9 Agent'").identifyingnumber
            #uninstalls bit9
            Start-Process msiexec.exe -ArgumentList "/x $guid /qn" -Wait
        }
        #verifies that bit9 has been uninstalled and writes results to host
        if($recheck -eq "Bit9 Agent")
        {
            write-host "$computer - Uninstall failed"
        }
        else
        {
            Write-Host "$computer - Uninstall successful"
        }
    }
    else
    {
        Write-Host "$computer - Bit9 not found on system"
    }
}


Write-Host "Press any key to continue..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")