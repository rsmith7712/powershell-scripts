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
    shared mailbox permissions, update for o365 migration_2.ps1

.DESCRIPTION
    For each member of a specified security group, grants individual Full Access and Send As permissions to a shared mailbox (run interactively, step by step).

.FUNCTIONALITY
    Assigns shared-mailbox Full Access and Send As from a security group.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#establish a remote shell connection to exchange, run these one at a time
#1
$UserCredential = Get-Credential

#2
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://srvexcas01/PowerShell/ -Authentication Kerberos -Credential $UserCredential

#3
Import-PSSession $Session



#for each member in a specified security group, assign the users individually full acess and send-as access to a shared mailbox
#update line 12 with the SG
#update line 21's get-mailbox with the display name of the shared mailbox
#update line 24's -Identity with the shared mailbox full email address

$Members = Get-ADGroupMember -id SG-SAAS-NICKSTEST 
ForEach ($Member in $Members){ 
	Get-Mailbox "mailbox1" | Add-ADPermission -User $Member.name -ExtendedRights "Send As"
	Add-MailboxPermission -Identity mailbox1@example.com -User $Member.name -AccessRights FullAccess -AutoMapping:$true -InheritanceType All 
} 