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
    fGet-BoSpStatus.ps1

.DESCRIPTION
    Parses the GlobalSTORE POS back-office service-pack install log to report whether the installation succeeded.

.FUNCTIONALITY
    Reports GlobalSTORE service-pack install status.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Get-BoSpStatus()
{
    $spSetupLog = Get-Content "c:\gstr\instlog\svrpossetup.log"
    $spStatus01 = "Product: Fujitsu GlobalSTORE DOMAIN Application POS -- Installation completed successfully."
    $spStatus02 = "Windows Installer installed the product. Product Name: Fujitsu GlobalSTORE DOMAIN Application POS. Product Version: 20.14.0. Product Language: 1033. Manufacturer: Fujitsu America, Inc.. Installation success or error status: 0."
    if($spSetupLog -match $spStatus01)
    {
        $boSpStatus0 = "[STATUS] : Fujitsu BackOffice Service Pack installation was successful."
    }
        else
        {
            $boSpStatus0 = "[STATUS] : Fujitsu BackOffice Service Pack installation was NOT successful."
        }
    if($spSetupLog -match $spStatus02)
    {
        $boSpStatus1 = "Fujitsu BackOffice Service Pack installation script exited successfully.  Please review the output from 'c:\gstr\instlog\svrpossetup.log' for addition information."
    }
        else
        {
            $boSpStatus1 = "Fujitsu BackOffice Service Pack installation script did NOT exit successfully. Please review the output from 'c:\gstr\instlog\svrpossetup.log' for addition information."
        }
    Process-Output -message $boSpStatus0,$boSpStatus1 -splunk $true
    return $boSpStatus0,$boSpStatus1
}#=========================================[End Function]==========================================
Get-BoSpStatus