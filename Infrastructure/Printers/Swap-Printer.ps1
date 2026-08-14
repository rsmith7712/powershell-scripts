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
    Swap-Printer.ps1

.DESCRIPTION
    Swaps the receipt-printer configuration on a prompted store register via a remote command with a service credential.

.FUNCTIONALITY
    Swaps a register's printer configuration remotely.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$SPW = ConvertTo-SecureString -AsPlainText -Force -String "<password>"
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "DOMAIN\ORGSVC", $SPW
#Creates Variables for login

#$GCPrinter = "TM-H6000IVU"
#$RecPrinter = "TM-T88VU"
#Creates Printer type variables


$reg = Read-Host "What Register?"
Invoke-Command -CN $reg -cred $cred -ScriptBlock {
    $GCPrinter = "TM-H6000IVU"
    $RecPrinter = "TM-T88VU"
    $currentprinter = Get-ItemProperty -Path HKLM:\Software\OLEForRetail\ServiceOPOS\POSPrinter
    If ($currentprinter.DefaultPOSPrinter -eq $GCPrinter){
        Set-ItemProperty –Path HKLM:\Software\OLEForRetail\ServiceOPOS\POSPrinter –Name DefaultPOSPrinter –Value TM-88VU
        } 
    Elseif ($currentprinter.DefaultPOSPrinter -like $RecPrinter){
        Set-ItemProperty –Path HKLM:\Software\OLEForRetail\ServiceOPOS\POSPrinter –Name DefaultPOSPrinter –Value TM-H6000IVU
        }
    Else{
        Write-Host "Its Broke!"
        }
    }