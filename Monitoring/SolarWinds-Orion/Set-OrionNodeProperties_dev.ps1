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
    Set-OrionNodeProperties_dev.ps1

.DESCRIPTION
    Sets the NodeName property of a SolarWinds Orion node (by IP) via SwisPowerShell (dev).

.FUNCTIONALITY
    Sets a SolarWinds Orion node property.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Import-Module SwisPowerShell
Import-Module PowerOrion
Function Set-OrionNodeProperties($apname,$ip,$swis)
{
    Try
    {
        $nodePropertiesUri = (Get-OrionNode -IPAddress $ip -SwisConnection $swis).Uri
        Set-SwisObject $swis $nodePropertiesUri @{NodeName = $apname} -ErrorAction Stop
        $output = "Successfully set the 'NodeName' property for $ip to $apname."
        Write-Host $output -ForegroundColor Yellow
    }
        Catch
        {
            $output = "ERROR: Failed to set the 'NoedName' property for $ip. Exception Message: $($_.Exception.Message)."
            Write-Host $output -ForegroundColor Cyan
        }
        Finally
        {
            $ErrorActionPreference = "SilentlyContinue"
        }
}
$apname = "2955-AP2"
$ip = "0.0.0.0"
$swis = Connect-Swis -Certificate

Set-OrionNodeProperties -apname $apname -ip $ip -swis $swis

$newname = (Get-OrionNode -IPAddress $ip -SwisConnection $swis).NodeName
Write-Host "NodeName: $newname | IP Address: $ip" -ForegroundColor Green