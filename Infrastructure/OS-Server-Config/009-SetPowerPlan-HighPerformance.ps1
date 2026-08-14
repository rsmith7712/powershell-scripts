# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
    009-SetPowerPlan-HighPerformance_2_2.ps1

.DESCRIPTION
    Defines a function to set the active Windows power plan (via powercfg); this copy is used to select the High Performance plan (variant).

.FUNCTIONALITY
    Sets the active Windows power plan.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function Set-PowerPlan ($powerPlan = "balanced") {
    try {
        $powerPlan = $powerPlan.toLower()
        $perf = powercfg -l | %{if($_.toLower().contains($powerPlan)) {$_.split()[3]}}
        $currentPlan = $(powercfg -getactivescheme).split()[3]

        if ($currentPlan -ne $perf) {
            powercfg -setactive $perf
        }
    } catch {
        Write-Warning -Message "Unabled to set power plan to $powerPlan"
    }
}

Set-PowerPlan("high performance")
