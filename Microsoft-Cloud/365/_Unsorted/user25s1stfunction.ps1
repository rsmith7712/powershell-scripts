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
    user25s1stfunction.ps1

.DESCRIPTION
    Practice script defining Exchange helper functions (import snap-in, disable on-premises mailbox) for mailbox migration.

.FUNCTIONALITY
    Exchange mailbox helper functions (practice script).

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
Function Disable-OnPremMailbox($aliass)
{
 #disable on-prem mailbox
    Disable-Mailbox  -Identity "$aliass" -Confirm:$false
    Return $?
}#===============================[ End Function ]==========================

Function Create-O365Mailbox($aliass)
{
    #Create new o365 mailbox
    Enable-RemoteMailbox -Identity $aliass -Alias $aliass -RemoteRoutingAddress ($aliass + "@domain.mail.onmicrosoft.com")
    Return $?
}#===============================[ End Function ]==========================
Function Add-o365Aliass($aliass) 
{
    #add alias email addresses
    Set-RemoteMailbox "$aliass" -EmailAddresses @{add='$($aliass)@example.com'}
    Return $?
}#===============================[ End Function ]==========================
Function Get-O365Mailbox($aliass)
{
    Try
    {
        Get-Mailbox -Identity $aliass -ErrorAction Stop
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

$csvImportFile = "\\SERVER\SHARE\...\MailboxRecovery1.csv"

    $csvImportFile | Import-Csv | ForEach-Object{
        [string]$aliasCSV = $_.Alias
        Write-Host "[STATUS] : Processing Mailbox for $($aliasCSV)"
        $ErrorActionPreference = "Stop"
        Try
        {
            $mbObj = Get-Mailbox -Identity $aliasCSV -ErrorAction Stop
            $aliass = $mbObj.alias
            Write-Host "This is the alias from AD/Exchange: $($aliass)" -ForegroundColor Yellow -BackgroundColor Black
        }
            Catch
            {
                $e = $($_.Exception.Message)
                Write-Host "[ERROR] : The following exception occurred when attempting to process $($aliasCSV). [[EXCEPTION] : $e`n`n" -ForegroundColor White -BackgroundColor Magenta
            }
            $ErrorActionPreference = "SilentlyContinue"

        # [Un-Comment to excecute this function] 
        $oldmbdisabled = Disable-OnPremMailbox -aliass $aliass
        #Write-Host "[STATUS] : Old Mailbox disabled status for $aliass : $oldmbdisabled" -ForegroundColor Yellow

        # [Un-Comment to excecute this function] 
        #$newmbCreated = Create-O365Mailbox -aliass $aliass
        #Write-Host "[STATUS] : New Mailbox creation status for $aliass : $newmbcreated" -ForegroundColor Green

        # [Not used for original mailbox migration] # [Un-Comment to excecute this function] Add-o365Aliass -aliass $aliass
    }
################################[ SCRIPT ENDS ]################################