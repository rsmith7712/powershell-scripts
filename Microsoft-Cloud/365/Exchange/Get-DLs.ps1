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
    Get-DLs.ps1

.DESCRIPTION
    Exports all distribution groups to CSV, flagging whether each restricts internal and external senders.

.FUNCTIONALITY
    Reports distribution-group sender restrictions.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$LogFile = "E:\Temp\DL_Export.csv"
If(!(Test-Path $LogFile)){
	New-Item $LogFile -type "File"
	}
Add-Content -Path $LogFile -Value "DL Name,Sender Restricted?,External Sender Restricted?"

$DLs = Get-DistributionGroup -ResultSize Unlimited
ForEach($DL in $DLs){
	If($DL.AcceptMessagesOnlyFrom.count -lt 1){
		Add-Content -Path $LogFile -Value "$($DL.Name),No,No"
	}
    Else{
        Add-Content -Path $LogFile -Value "$($DL.Name),Yes,No"
    }
}