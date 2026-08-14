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
    fSet-userWorkstationsAttributeValue.ps1

.DESCRIPTION
    Populates the 'userWorkstations' Active Directory attribute for a store's self-checkout (SCO) hosts.

.FUNCTIONALITY
    Sets the userWorkstations AD attribute for store hosts.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Get-SCOComputers($UFO_NUMBER)
{
    $ErrorActionPreference = "Stop"
    Try
    {
        $ScoHosts = @()
        (Get-ADComputer -Filter "name -like '$($UFO_NUMBER)SCO*'").Name |
        ForEach-Object{
            $scoHosts += $_
        }
        Append-Log "[STATUS] : Adding the following host(S) to the 'userWorkstations' list attribute in AD for:`n$ScoHosts"
        $ScoHosts
    }
        Catch
        {
            Append-Log "[EXCEPTION] : The following exception occurred: $($_.Exception.Message)."
        }
        $ErrorActionPreference = "Continue"

    if(($null -like $ScoHosts) -or ($ScoHosts -like ""))
    {
        Write-Host "Generating SCO Hostname." -ForegroundColor Yellow
        $ErrorActionPreference = "Stop"
        Try
        {
            $regArray = @()
            (Get-ADComputer -filter "samAccountName -like '*$($UFO_NUMBER)REG*'" -SearchBase "DC=DOMAIN,DC=com").Name |
            ForEach-Object{
                $regName = $_
                [int]$regSuffix = ($regName -Split "g")[1]
                $regArray += $regSuffix
            }
            $var = ($regArray | Sort-Object)[-1] + 1
            [string]$suffix = $var
            $ScoHosts = $([string]$UFO_NUMBER) + "SCO" + $suffix
        }
            Catch
            {
                Append-Log "[EXCEPTION] : The following exception occurred: $($_.Exception.Message)."
            }
            $ErrorActionPreference = "Continue"
    }

    return $ScoHosts
}#=======================================[ End Function ]==========================================

$ScoHosts = Get-SCOComputers -UFO_NUMBER 2162

$ScoHosts 
