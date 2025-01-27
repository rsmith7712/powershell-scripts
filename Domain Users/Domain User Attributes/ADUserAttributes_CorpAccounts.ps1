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
   - ADUserAttributes_CorpAccounts.ps1

.SYNOPSIS
   - 

.FUNCTIONALITY
    Prompts for Input, or Does It?

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$outfile = "c:\logs\ADUserAttributes_CorpAccounts.csv"
if(Test-Path $outfile){rm $outfile}

# Define OU's to be processed

$OUs = @("OU=Corporate Accounts,DC=DOMAIN,DC=com")

# Define Variables and Process user objects from affected OU's
$OUs | foreach{
Get-ADuser -Filter * -SearchBase $_ -SearchScope Subtree -Properties * | foreach{
    $name = $_.Name
    $lastname = $_.Surname
    $firstname = $_.GivenName
    $upn = $_.UserPrincipalName
    $samid = $_.SamAccountName
    $title = $_.title
    $managerdn = $_.manager
    # if($managerdn -eq $null){$manager = "NOT FOUND"}
    $manager = (Get-ADUser $managerdn).name
    $office = $_.office
    $officephone = $_.OfficePhone
    $dept = $_.department
    $org = $_.organization

    #Create Custom Object properties
    $props = @{LastName=$lastname
               FirstName=$firstname
               FullName=$name
               UPN=$upn
               SamAccountName=$samid
               Title=$title
               Office=$office
               OfficePhone=$officephone
               Manager=$manager
               Department=$dept
               Organization=$org}
    $obj = New-Object -TypeName PSObject -Property $props

    # Export custom PSObject into CSV formatted output
    $obj | Export-Csv -Path $outfile -Append -NoTypeInformation
    }
}
Invoke-Item $outfile