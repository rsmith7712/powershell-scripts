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
    Install_SQLEXPRESS.ps1

.DESCRIPTION
    Installs SQL Server Express from a configuration file and sets its TCP port to 1433 via the registry.

.FUNCTIONALITY
    Installs and configures SQL Server Express.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Start-Process -FilePath "C:\Software\sqlexpress\Setup.exe" -ArgumentList '/SQLSVCPASSWORD="<password>" /SAPWD="<password>" /CONFIGURATIONFILE=c:\Software\sqlexpress\R2config.ini' -Wait -NoNewWindow
$regpath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.SQLEXPRESS\"
$regpath1 = $regpath + "MSSQLServer\SuperSocketNetLib\Tcp\IP1"
$regpath2 = $regpath + "MSSQLServer\SuperSocketNetLib\Tcp\IPAll"
Set-ItemProperty -Path $regpath1 -Name "TcpPort" -Value "1433"
Set-ItemProperty -Path $regpath2 -Name "TcpDynamicPorts" -Value "1433"