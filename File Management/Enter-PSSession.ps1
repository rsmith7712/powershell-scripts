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
    Enter-PSSession.ps1

.DESCRIPTION
    Enter a PowerShell session on a remote computer using the Enter-PSSession
    cmdlet.  This script is designed to be used as a template for entering a
    PowerShell session on a remote computer.  The script will prompt the user
    for credentials and then enter a PowerShell session on the specified
    remote computer.

.FUNCTIONALITY
    This script is designed to be used as a template for entering a PowerShell
    session on a remote computer.  The script will prompt the user for credentials
    and then enter a PowerShell session on the specified remote computer. The
    script can be modified to include additional functionality as needed.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# Option 1: Using Get-Credential
$cred = Get-Credential

        # Option 2: Manual credential creation
        #$username = "Administrator"
        #$password = ConvertTo-SecureString "YourPassword" -AsPlainText -Force
        #$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $password

#Enter-PSSession -ComputerName Shipping-Ws2 -Credential $cred   #Shipping Backup Workstation

Enter-PSSession -ComputerName JFU-LT01 -Credential $cred       #OS
