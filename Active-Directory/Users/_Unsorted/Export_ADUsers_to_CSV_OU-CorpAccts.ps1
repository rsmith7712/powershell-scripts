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
    Export_ADUsers_to_CSV_OU-CorpAccts_v1.ps1

.DESCRIPTION
    Exports the users in the Corporate Accounts OU to a date-stamped CSV (v1).

.FUNCTIONALITY
    Exports Corporate Accounts OU users to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Define location of script variable
#the -parent switch returns one directory lower from directory defined. 
#below will return up to ImportADUsers folder 
#and since files are located here it will find it.
#It fails without appending "*.*" at the end
# commenting out to bypass - $path = Split-Path -parent "C:\HOLD\powershell_scripts\ExportADUsers\*.*"


#Create a variable for the date stamp in the log file
$LogDate = get-date -f yyyyMMddhhmm


#Define CSV and log file location variables
#they have to be on the same location as the script
# commenting out to bypass - $csvfile = $path + "\ALLADUsers_$logDate.csv"


#import Modules
Import-Module ActiveDirectory
#Import-Module ShowUI


#Sets the OU to do the base search for all user accounts, change as required.
$SearchBase = "OU=corporate accounts,DC=Domain,DC=com"


#Get Admin accountb credential
#$GetAdminact = Get-Credential / #-Credential $GetAdminact 


#Define variable for a server with AD web services installed
$ADServer = 'st2-dc1'


#Define "Account Status" 
$AllADUsers = Get-ADUser -server $ADServer `
-searchbase $SearchBase `
-Filter * -Properties * | Where-Object {$_.info -NE 'Migrated'} #ensures that updated users are never exported.

$AllADUsers |
Select-Object @{Label = "First Name";Expression = {$_.GivenName}},
@{Label = "Last Name";Expression = {$_.Surname}},
@{Label = "Display Name";Expression = {$_.DisplayName}},
@{Label = "Logon Name";Expression = {$_.sAMAccountName}},
@{Label = "Full address";Expression = {$_.StreetAddress}},
@{Label = "City";Expression = {$_.City}},
@{Label = "State";Expression = {$_.st}},
@{Label = "Post Code";Expression = {$_.PostalCode}},
@{Label = "Country/Region";Expression = {if (($_.Country -eq 'GB')  ) {'United Kingdom'} Else {''}}},
@{Label = "Job Title";Expression = {$_.Title}},
@{Label = "Company";Expression = {$_.Company}},
@{Label = "Description";Expression = {$_.Description}},
@{Label = "Department";Expression = {$_.Department}},
@{Label = "Office";Expression = {$_.OfficeName}},
@{Label = "Phone";Expression = {$_.telephoneNumber}},
@{Label = "Email";Expression = {$_.Mail}},
@{Label = "Manager";Expression = {%{(Get-AdUser $_.Manager -server $ADServer -Properties DisplayName).DisplayName}}},
@{Label = "Account Status";Expression = {if (($_.Enabled -eq 'TRUE')  ) {'Enabled'} Else {'Disabled'}}}, # the 'if statement# replaces $_.Enabled
@{Label = "Last LogOn Date";Expression = {$_.lastlogondate}} | 


#Export CSV report
Export-Csv c:\Export_ADUsers_to_CSV_OU-CorpAccts.csv -NoTypeInformation



# Saved for future popup
#Add-Type -AssemblyName System.Windows.Forms
#$form = New-Object Windows.Forms.Form
#$form.Size = New-Object Drawing.Size @(200,100)
#$form.StartPosition = "CenterScreen"
#$btn = New-Object System.Windows.Forms.Button
#$btn.add_click({Get-Date|Out-Host})
#$btn.Text = "Click here"
#$form.Controls.Add($btn)
#$drc = $form.ShowDialog()
