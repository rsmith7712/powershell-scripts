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
    Getstore.psm1
 
 .Synopsis
  Gets the connection status of stores plus register # and type

 .Description
  Displays in a hash table the store, register number and type

 .Parameter Start
  UFO_NUMBER

 .Example
   # Show a default display of this month.
   Get-Store

 .Example
   # Display a date range.
   Get-site

.FUNCTIONALITY
    Displays in a hash table the store, register number and type

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function Get-Store ($storeno) {
    [int] $oldregmin = 6
    [int] $oldregmax = 12
    [int] $newregmin = 51
    [int] $newregmax = 59
    [string] $storedown = "Store is either down or does not exist"
    [hash] $totalstorereg = @{}

    if ($storeno -lt 100) {
        $storeip = "10.0.$storeno."
        } 
    elseif ($storeno -lt 200 -and $storeno -ge 100) {
        $storenum = $storeno - 100
        $storeip = "10.1.$storenum."
        } 
    elseif ($storeno -lt 300 -and $storeno -ge 200) {
        $storenum = $storeno - 200
        $storeip = "10.2.$storenum."
        } 
    elseif ($storeno -lt 400 -and $storeno -ge 300) {
        $storenum = $storeno - 300
        $storeip = "10.3.$storenum."
        } 
    elseif ($storeno -lt 500 -and $storeno -ge 400) {
        $storenum = $storeno - 400
        $storeip = "10.4.$storenum."
        } 
    elseif ($storeno -lt 600 -and $storeno -ge 500) {
        $storenum = $storeno - 500
        $storeip = "10.5.$storenum."
        } 
    elseif ($storeno -lt 700 -and $storeno -ge 600) {
        $storenum = $storeno - 600
        $storeip = "10.6.$storenum."
        } 
    elseif ($storeno -lt 800 -and $storeno -ge 700) {
        $storenum = $storeno - 700
        $storeip = "10.7.$storenum."
        }
    else {
        $totalstorereg = $storedown
        }
    If (test-connection ($storeip + "1") -Count 1 -Delay 1) {
        $totalstorereg += @{"Store #" = $storeno}
        #Store Register Count
        while ($oldregmin -le $oldregmax){
            if (test-connection ($storeip + $oldregmin) -Count 1 -Delay 1 -ErrorAction SilentlyContinue){
                $oldregno += 1
                $oldregmin += 1
                }
            else {
                $oldregmin += 1
                }
            }
        #Gather Store Info
        If ($oldregno -gt 0) {
            $totalstorereg += @{Apropos = $oldregno}
            $oldregno = 0
            }
        #Store Register Count
        while ($newregmin -le $newregmax){
            if (test-connection ($storeip + $newregmin) -Count 1 -Delay 1 -ErrorAction SilentlyContinue){
                $newregno += 1
                $newregmin += 1
                }
            else {
                $newregmin += 1
                }
            }
        #Gather Store Info
        If ($newregno -gt 0) {
            $totalstorereg += @{Starmount = $newregno}
            $newregno = 0
            }
        }
    else {
        $totalstorereg += @{"Store #" = $storeno}
        $totalstorereg = @{Status = $storedown}
    }
    return $totalstorereg
    $totalstorereg
}

export-modulemember -function Get-Store