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
    fJoin-Domain.ps1

.DESCRIPTION
    Joins a computer to the domain (checking DNS reachability and current membership) using a service account.

.FUNCTIONALITY
    Joins a computer to the domain.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Join-Domain($domainname,$dns,$ou,$svcacct,$svcacctpw)
{
    $alreadyPart = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
    switch($alreadyPart)
    {
    $false          
        {
            $domainCheck = Test-Connection $dns[0] -Quiet
            if($domainCheck -eq $false)
            {
                $secondCheck = Test-Connection $dns[1] -Quiet
                if($secondCheck -eq $false)
                {
                    $status ="[WARNING] : Unable to establish domain $($domainname) connectivity. Skipping domain join operation."
                }
            }
            # join this computer to example.com domain
            $domainUser = "$($domainname)\$svcacct"
            $domainPass = ConvertTo-SecureString $svcacctpw -AsPlainText -Force
            Try
            {
                $domainCred = New-Object System.Management.Automation.PSCredential $domainUser, $domainPass
                Add-Computer -DomainName $domainname -OUPath $ou -credential $domainCred
                if($? -eq $false)
                {
                    $status ="[WARNING] : Issue encountered while joining the $($domainname) domain. Exiting domain join operation."
                }
                    else
                    {
                        $status = "[SUCCESS] : Joined to $($domainname) Domain."
                    }
            }
                Catch
                {
                    $status = "[ERROR] : Issue encountered while joining the $($domainname) domain. Exiting domain join operation. Exception: $($_.Exception.Message)."
                }
        }
    $true
        {
            $status ="[SUCCESS] : $($env:COMPUTERNAME) is already a member of the $($domainname) domain."
        }
    }
    return $status
}#=========================================[End Function]==========================================
$ou = "OU=Store Computers,OU=Store Computers,DC=DOMAIN,DC=com"
$dns = "0.0.0.0","0.0.0.0"
[string]$svcacct = "slcadmin"
[string]$svcacctpw = "<password>"
[string]$domainname = "example.com"
##########################################[Script Starts]##########################################
$status = Join-Domain -dns $dns -ou $ou -domainname $domainname -svcacct $svcacct -svcacctpw $svcacctpw
Write-Host $status
Exit
###########################################[Script Ends]###########################################