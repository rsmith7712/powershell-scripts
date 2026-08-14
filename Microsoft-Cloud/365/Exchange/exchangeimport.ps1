# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Richard Smith

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
    exchangeimport.ps1

.DESCRIPTION
    Imports store mailbox data from a CSV and selects display fields (with a commented-out group-membership processing block).

.FUNCTIONALITY
    Imports store mailbox data from a CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$csvInPath = "C:\temp\Read\StoreMailboxes.csv"
$csvIn = Import-Csv -Path $csvInPath | Where-Object{$_ -like "dISPLAY"}
$csvIn | Select-Object $display

<#
$csvIn | ForEach-Object{
        $Display = $_.DisplayNam
        $EmailAddress = $_.emailaddress
        $Alias = $_.alias
        $ADDAlias = $_.Addalias
        Write-Host "[STATUS] : Processing User: $($ADDAlias): Finding Group Memberships"

    }
     <#   #$smtpAddrs = Get-365MailBox -samAccountName $memberSamAccountName

        Write-Host $smtpAddrs -ForegroundColor Green -BackgroundColor Black #[for debug purposes - remove when finished testing]
        Write-Host "[STATUS] : Processing User: $($memberName): Creating new mailbox"
        #$mbCreationStatus = Create-365MailBox -samAccountName -groups $smtpAddrs
        if ($mbCreationStatus)
        {
            Process-Output -message "[STATUS] : User: $($memberName): New mailbox creation successful." -color "Green"
        }
            else
            {
                Process-Output -message "[STATUS] : User: $($memberName): New mailbox creation failed" -color "Red"
            }
    }

Exit
#>