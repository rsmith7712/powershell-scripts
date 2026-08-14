
## 1 -- Verified Working
#List members of an existing security group:
#Get-ADGroupMember "SM-Payroll-Full" | Select-Object Name

## 2 -- Verified Working
<#
Existing way we applied permissions to security groups
(these could maybe be used if we had a way to extract the
userlist and format them in the –User area in an easy way?)
#>
# Full access:
#Add-MailboxPermission -id "sharedmailbox" -User "securitygroup" -AccessRights Fullaccess -WhatIf

#Send as permission:
#Get-Mailbox "Mailboxname" | Add-ADPermission -User "Name or group name" -ExtendedRights "Send As" -WhatIf


## 3
<#
Two scripts I modified / found online for cycling through an
existing security group, and for each member, adding their permissions

This one errors out while trying to look up the security group,
claiming the group doesn’t exist on SRVDC2 (it exists..? Weird).
This one would do both full access and send-as access, which would be cool!
#>
$Members = Get-DistributionGroupMember -id SG-SAAS-NICKSTEST
ForEach ($Member in $Members){
Add-RecipientPermission mailbox2 -AccessRights SendAs -Trustee $Member.name
Add-MailboxPermission -Identity mailbox2@example.com -User $Member.name -AccessRights FullAccess -AutoMapping:$true -InheritanceType All
}


## 4
<#
This one is only for full access, but could maybe be useful still
errors out (hard to decipher exactly why)
#>
$DL = Get-DistributionGroupMember "SG-SAAS-NicksTest" | Select-Object -ExpandProperty Name
    ForEach ($member in $DL){
        Add-MailboxPermission -Identity 'mailbox2' -User $Member -AccessRights 'FullAccess' -InheritanceType All
    }