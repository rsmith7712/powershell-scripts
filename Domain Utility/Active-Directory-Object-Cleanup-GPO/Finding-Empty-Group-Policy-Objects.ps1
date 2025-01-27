# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Tim Buntrock

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
   - Finding-Empty-Group-Policy-Objects.ps1

.SYNOPSIS
   - PowerShell script that helps you find and delete
    unlinked Group Policy Objects (GPO), also known
    as orphaned GPOs. Orphaned GPOs are not linked
    to any Active Directory sites, domains, or
    organizational units (OUs). This can cause
    various problems. Using PowerShell, it is easy
    to create reports of unlinked GPOs, back them up,
    and eventually delete them.

.FUNCTIONALITY
   - https://4sysops.com/archives/find-and-delete-unlinked-orphaned-gpos-with-powershell/

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

########################
###### EXPLANATION #####
########################

<#
To find unlinked GPOs, we will use the Get-GPO and
Get-GPOReport commands, which belong to the Group
Policy module that is a part of RSAT. You can import
the module with this command:
#>
#Import-Module GroupPolicy

<#
To retrieve all GPOs, we use the -All parameter and
use Get-GPOReport to cast them to an XML object. We
pipe the result to Select-String, which finds us all
lines without "<LinkTo>".
#>
#Get-GPO -All | Sort-Object displayname | Where-Object { If ( $_ | Get-GPOReport -ReportType XML | Select-String -NotMatch "<LinksTo>" ){$_.DisplayName }}`

<#
To log these GPOs to a text file, you just have to
add this line after $_.DisplayName:
#>
#| Out-File "c:\admin\GPOBackup \UnLinkedGPOs.txt" –Append

<#
Because you might not want to delete GPOs before
creating a backup, we need a variable for our backup
location#>
#$BackupPath = "c:\GPOBackup"

<#
The next command creates the backup
#>
#Backup-GPO -Name $_.DisplayName -Path $BackupPath

<#
To create a report of unlinked GPOs, we have to use
Get-GPOReport again. However, instead of using XML,
we will set the ReportType to HTML.
#>
#Get-GPOReport -Name $_.DisplayName -ReportType Html -Path "c:\GPOBackup\$Date\$($_.DisplayName).html"

<#
As the last step, we delete those GPOs using the
Remove-GPO cmdlet:
#>
#$_.Displayname | Remove-GPO -Confirm


########################
######## MAIN ##########
########################

<#
Let´s put all of these parts together. The only
thing I added is a $Date variable to identify
backups from different days.

You can run this script as a scheduled task to
automate GPO cleanup.

If you simply want to create a report without
automatically removing GPOs, you can
remove $_.Displayname | remove-gpo –Confirm from
the command. 

You can then check your backup location to take
a closer look at orphaned GPOs. You can also send
e-mails that inform you about new, unlinked GPOs.

This is accomplished with the Send-MailMessage cmdlet
that I added at the end of the script.
#>

Install-WindowsFeature GPMC
Import-Module GroupPolicy
$Date = Get-Date -Format dd_MM_yyyy
$BackupPath = "c:\GPOBackup\$Date"
if (-Not(Test-Path -Path $BackupPath)) 
{ New-Item -ItemType Directory $BackupPath -Force}
Get-GPO -All | Sort-Object displayname | Where-Object { If ( $_ | Get-GPOReport -ReportType XML | Select-String -NotMatch "<LinksTo>" )
 {
   Backup-GPO -Name $_.DisplayName -Path $BackupPath
   Get-GPOReport -Name $_.DisplayName -ReportType Html -Path "c:\GPOBackup\$Date\$($_.DisplayName).html"
   $_.DisplayName | Out-File "c:\GPOBackup\$Date\UnLinkedGPOs.txt" -Append
   
   #Commented out automatic removal of identified GPOs; NEED CCB APPROVAL FIRST!
   #$_.Displayname | remove-gpo -Confirm
   
   #Set E-mail variables.
   $EmailFrom = "GPOReport@bdainc.com"
   $EmailTo = "rsmith@bdainc.com"
   $Subject = "Unlinked GPO Report"
   $Body = (Get-Content $BackupPath\UnLinkedGPOs$Date.txt | Out-String)
   $SMTPServer = "mail.bdainc.bda"
   #Send Email
   Send-MailMessage -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Priority High -To $EmailTo -From $EmailFrom
   }
}