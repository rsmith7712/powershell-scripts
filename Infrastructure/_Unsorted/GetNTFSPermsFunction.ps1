function Get-NTFSPermissions {

<#

.SYNOPSIS

Gets the NTFS rights set on a folder.

.DESCRIPTION

Gets the NTFS rights set on a folder and outputs the groups and users (recursive) in those groups.

The output can be redirected to a CSV or manipulated by using PowerShell cmdlets.

.PARAMETER ShareName

This parameter takes the name of the share you want to get the NTFS rights from as input.

.PARAMETER DomainName

This parameter takes the NETBIOS name of your domain as input.

.PARAMETER GroupsOnly

This parameter is not mandatory and allows you to output only the shares, groups

and their respective rights.

.EXAMPLE

Get-FolderRights -ShareName '\\SERVER\SHARE\folder' -DomainName 'AD'


This example takes the name and path of the share as input, aswell as the NETBIOS name of the domain.

.EXAMPLE

Get-FolderRights -ShareName '\\SERVER\SHARE\folder' -DomainName 'AD' | Convertto-CSV | Out-file NTFSRights.csv


This example takes the name and path of the share as input, aswell as the

NETBios name of the domain.     Next the output is converted to CSV and written to a CSV file.

.EXAMPLE

Get-FolderRights -ShareName '\\SERVER\SHARE\folder' -DomainName 'AD' -GroupsOnly


This example takes the name and path of the share as input, aswell as the NETBIOS name of the domain.

Because the -GroupsOnly parameter is used, only rights for the groups are

gathered and not the users inside the groups.

.NOTES

AUTHOR    :  Jeff Wouters

COMPANY   :  Methos

#>

#Requires -Modules ActiveDirectory
    [cmdletbinding()]
    param (
        [parameter(mandatory=$true,position=0)]$ShareName,
        [parameter(mandatory=$true,position=1)]$DomainName,
        [parameter(mandatory=$false)][switch]$GroupsOnly
    )
    $Output = @()
    foreach ($Share in $ShareName) {
        $ACLs = Get-Acl -Path $Share
        foreach ($ACL in $ACLs) {
            foreach ($AccessRight in $ACL.Access) {
                $ObjectGroup = New-Object -TypeName PSObject
                $ObjectGroup | Add-Member -MemberType NoteProperty -Name 'DirectoryPath' -Value $Share
                $ObjectGroup | Add-Member -MemberType NoteProperty -Name 'Identity' -Value $AccessRight.IdentityReference
                $ObjectGroup | Add-Member -MemberType NoteProperty -Name 'SystemRights' -Value $AccessRight.FileSystemRights
                $ObjectGroup | Add-Member -MemberType NoteProperty -Name 'SystemRightsType' -Value $AccessRight.AccessControlType
                $ObjectGroup | Add-Member -MemberType NoteProperty -Name 'IsInherited' -Value $AccessRight.IsInherited
                $ObjectGroup | Add-Member -MemberType NoteProperty -Name 'InheritanceFlags' -Value $AccessRight.InheritanceFlags
                $ObjectGroup | Add-Member -MemberType NoteProperty -Name 'RulesProtected' -Value $ACL.AreAccessRulesProtected
                if ($GroupsOnly -eq $true) {
                    $ObjectGroup
                } else {
                    $Groups = $ObjectGroup | Select-Object -ExpandProperty 'Identity'
                    foreach ($Group in $Groups) {
                        if ($Group -like "$DomainName\*") {
                            $grp = $Group.tostring()
                            $gp = $grp.replace("$DomainName\",'')
                            $Users = Get-ADGroupMember -Recursive -Identity $gp
                            foreach ($User in $Users) {
                                $ObjectUser = New-Object -TypeName PSObject
                                $ObjectUser | Add-Member -MemberType NoteProperty -Name 'DirectoryPath' -Value $Share
                                $ObjectUser | Add-Member -MemberType NoteProperty -Name 'Group' -Value $gp
                                $ObjectUser | Add-Member -MemberType NoteProperty -Name 'SystemRights' -Value $ObjectGroup.SystemRights
                                $ObjectUser | Add-Member -MemberType NoteProperty -Name 'SystemRightsType' -Value $ObjectGroup.SystemRightsType
                                $ObjectUser | Add-Member -MemberType NoteProperty -Name 'IsInherited' -Value $ObjectGroup.IsInherited
                                $ObjectUser | Add-Member -MemberType NoteProperty -Name 'InheritanceFlags' -Value $ObjectGroup.InheritanceFlags
                                $ObjectUser | Add-Member -MemberType NoteProperty -Name 'RulesProtected' -Value $ObjectGroup.RulesProtected
                                $Usr = $User | Select-Object -expandproperty 'samaccountname'
                                $ObjectUser | Add-Member -MemberType NoteProperty -Name 'UserName' -Value $Usr
                                $ObjectUser
                            }
                        }
                    }
                }
            }
        }
    }
}
