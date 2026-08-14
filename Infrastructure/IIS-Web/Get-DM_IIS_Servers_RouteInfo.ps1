# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Get-DM_IIS_Servers_RouteInfo.ps1

.DESCRIPTION
    Gathers network route information from a list of IIS servers and exports the results to CSV.

.FUNCTIONALITY
    Collects route info from IIS servers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Get-DM_IIS_Servers_RouteInfo.ps1

#Import Target List
$ComputerName = Get-Content C:\Temp\Targets.txt

#Exported results CSV
$Servers_NetInfo ="C:\Temp\DM_IIS_Servers_RouteInfo.csv" 

#Create an array to store results
$results = @()

#Create ForEach loop to process Target List
foreach ($Computer in $ComputerName)
{
  if(Test-Connection -ComputerName $Computer -Count 1 -ea 0)
    {
        $OutputObj = Get-WmiObject Win32_IP4RouteTable -ComputerName $Computer | select destination,mask,nexthop, metric1

        $results += $OutputObj
    }
} $results | Export-CSV -NoTypeInformation $Servers_NetInfo #Dump results to CSV for review