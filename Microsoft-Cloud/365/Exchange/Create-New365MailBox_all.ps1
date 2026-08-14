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
    Create-New365MailBox_all.ps1

.DESCRIPTION
    Migrates accounts to Office 365 from a CSV of aliases: disables the on-premises mailbox, enables a remote (O365) mailbox, adds alias addresses and verifies the result.

.FUNCTIONALITY
    Bulk-creates Office 365 remote mailboxes from a CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Import-ExchangePSModule()
{
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;   
    Return $?
}#===============================[ End Function ]==========================
Function Disable-OnPremMailbox($aliasCSV)
{
 #disable on-prem mailbox
    Disable-Mailbox  -Identity "$aliasCSV" -Confirm:$false
    Return $?
}#===============================[ End Function ]==========================

Function Create-O365Mailbox($aliasCSV)
{
    #Create new o365 mailbox
    Enable-RemoteMailbox -Identity $aliasCSV  -RemoteRoutingAddress ($aliasCSV + "@domain.mail.onmicrosoft.com")
    Return $?
}#===============================[ End Function ]==========================
Function Add-o365Aliass($aliasCSV) 
{
    #add alias email addresses
    Set-RemoteMailbox [string]$aliasCSV -EmailAddresses @{add='[string]$($aliasCSV)@example.com'}
    Return $?
}#===============================[ End Function ]==========================
Function Get-O365Mailbox($aliasCSV)
{
    Try
    {
        Get-Mailbox -Identity $($aliasCSV) -ErrorAction Stop
    }
        Catch
        {
            $e = $($_.Exception.Message)
            Write-Host "[EXCEPTION] : $e`n`n" -ForegroundColor White -BackgroundColor Magenta
        }
        $ErrorActionPreference = "SilentlyContinue"
    Return $?
}#===============================[ End Function ]==========================

################################[ SCRIPT STARTS ]##########################

# [Un-Comment to excecute this function] 

Import-ExchangePSModule

$csvImportFile = "\\SERVER\SHARE\...\MailboxRecovery.csv"
    $csvImportFile | Import-Csv | #Where-Object{[regex]$($_.Alias) -match "MGR"} | 
    ForEach-Object{
        [string]$aliasCSV = $_.Alias
        Write-Host "[STATUS] : Processing Mailbox for $($aliasCSV)"
        Try
        {
            $mbObj = ""
            $mbObj = Get-Mailbox -Identity $aliasCSV -ErrorAction Stop
            Write-Host "$($mbObj.Alias)" -ForegroundColor Yellow -BackgroundColor Black
            $output = "This is the alias from AD/Exchange: $($mbObj.Alias)" #$($aliasCSV)"
            Write-Host $output 
        }
            Catch
            {
                $e = $($_.Exception.Message)
                $output = "[ERROR] : The following exception occurred when attempting to process $($aliasCSV). [[EXCEPTION] : $e`n`n"
                Write-Host $output -ForegroundColor White -BackgroundColor Red
            }
            #>

            $ErrorActionPreference = "SilentlyContinue"

        # [Un-Comment to excecute this function] 
        $oldmbdisabled = Disable-OnPremMailbox -aliasCSV $aliasCSV
        Write-Host "[STATUS] : Old Mailbox disabled status for $aliasCSV : $oldmbdisabled" -ForegroundColor Yellow

        # [Un-Comment to excecute this function] 
        $newmbCreated = Create-O365Mailbox -aliasCSV $aliasCSV
        Write-Host "[STATUS] : New Mailbox creation status for $aliasCSV : $($newmbCreated)" -ForegroundColor Magenta
        Get-RemoteMailbox -Identity $aliasCSV # -ErrorAction Stop

        # [Not used for original mailbox migration] # [Un-Comment to excecute this function] Add-o365Aliass -$aliasCSV $aliasCSV
    }
################################[ SCRIPT ENDS ]################################