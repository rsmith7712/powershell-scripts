# FindOrphanedAdminSDHolders.ps1
# PowerShell version 1 script to find all orphaned objects in the forest. These are
# objects that were once members of any protected groups subject to AdminSDHolder,
# but which are no longer. The script also documents all protected objects.
# This script assumes you have not modified the AdminSDHolder object to enable
# inheritance for protected objects.
#
# Copyright (c) 2016 Richard L. Mueller
# Version 1.0 - January 14, 2016
# Version 1.1 - January 24, 2016 - Modified when Domain Controllers group protected.
#
# ----------------------------------------------------------------------
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the copyright owner above has no warranty, obligations,
# or liability for such use.

# Array of RID values of all default protected groups and users. Using the RID values
# allows the script to identify the objects even if any are renamed.
# RID  DN (except domain components)             Class
# ---  ----------------------------------------  ------
# 512  cn=Domain Admins,cn=Users                 group
# 516  cn=Domain Controllers,cn=Users            group
# 517  cn=Cert Publishers,cn=Users               group
# 518  cn=Schema Admins ,cn=Users                group
# 519  cn=Enterprise Admins,cn=Users             group
# 521  cn=Read-Only Domain Controllers,cn=Users  group
# 544  cn=Administrators,cn=Builtin              group
# 552  cn=Replicator,cn=Builtin                  group
# 548  cn=Account Operators,cn=Builtin           group
# 549  cn=Server Operators,cn=Builtin            group
# 550  cn=Print Operators,cn=Builtin             group
# 551  cn=Backup Operators,cn=Builtin            group
# 500  cn=Administrator,cn=Users                 user
# 502  cn=krbtgt,cn=Users                        user

Function GetNestedGroups($GrpDN, $Indent)
{
    # Recursive function to retrieve nested group members of a group.
    $Group = [ADSI]"LDAP://$GrpDN"
    # Consider all direct members of the group.
    ForEach ($MemberDN In $Group.Member)
    {
        # Avoid error if distinguished name contains the "/" character.
        $MemberDN = $MemberDN -Replace "/", "\/"
        $Member = [ADSI]"LDAP://$MemberDN"
        $MemberClass = $Member.objectClass
        # Every object has at least two classes in the array. The script needs to
        # retrieve the most specific, which will be the last entry in the array.
        $Class = $MemberClass[$MemberClass.Count - 1]
        # Consider only group members.
        If ($Class -eq "group")
        {
            # Check if the group is already in the hash table of protected groups.
            If ($Script:ProtGrps.ContainsKey($MemberDN) -eq $False)
            {
                # Retrieve the RID of the group from objectSID.
                $SID = $Member.objectSID
                $arrSID = ($SID.ToString()).Split()
                $k = $arrSID.Count
                $RID = [Int32]$arrSID[$k - 4] `
                    + (256 * [int32]$arrSID[$k - 3]) `
                    + (256 * 256 * [Int32]$arrSID[$k - 2]) `
                    + (256 * 256 * 256 * [Int32]$arrSID[$k - 1])
                # Add this nested group to the hash tables.
                $Script:ProtGrps.Add($MemberDN, $RID)
                $Script:ProtGroupRIDs.Add($RID, $MemberDN)
                # Add this group to Filter1.
                # Also include users or computers where this group is the primary.
                $Script:Filter1 = $Script:Filter1 `
                    + "(memberOf=" + $MemberDN `
                    + ")(primaryGroupID=$RID)"
                # Add this group to Filter2.
                # Also exclude users or computers where this group is the primary.
                $Script:Filter2 = $Script:Filter2 `
                    + "(!(memberOf=" + $MemberDN `
                    + "))(!(primaryGroupID=$RID))"
                # Determine if inheritance enabled for this object.
                $Entry = $Member.nTSecurityDescriptor
                # The use of psbase is required to support PowerShell V1.
                $GroupInherit = $Entry.psbase.ObjectSecurity.AreAccessRulesProtected
                If ($GroupInherit -eq "True") {$Inherit = "Inheritance disabled"}
                Else {$Inherit = "Inheritance enabled"}
                # Output the group indented to show nesting.
                "  $Indent$MemberDN (" + $Member.sAMAccountName + ", nested, $Inherit)"
                $Script:NumNestedProtGroups = $Script:NumNestedProtGroups + 1
                # Call this function recursively.
                GetNestedGroups $MemberDN "$Indent  "
            }
            Else
            {
                # Output the group indented to show nesting.
                # Indicate this is a duplicate. Do not increment count of groups.
                "  $Indent$MemberDN (Duplicate, see above)"
                # Do not call the recursive function, in case we have
                # circular nested groups, which would result in an infinite loop.
                # Any nested group members would be duplicates anyway.
            }
        }
    }
}

Function GetProtGroup($DirectGroups, $PriGroupRID)
{
    # Function to determine object membership in a protected group. This
    # results in the object being protected by DSProp and AdminSDHolder.
    # Because the hash table $ProtGrps includes all protected groups, even
    # due to group nesting, we only need to check the direct group memberships
    # of the object in the memberOf attribute. However, we also need to check
    # the primary group of the object. $PriGroupRID is the value of the
    # primaryGroupID of the object. The function returns the distinguished name
    # of the first group membership found that is protected.
    # Groups do not have a primaryGroupID attribute, so we must only consider
    # cases where $PriGroupRID has a value.
    If ($PriGroupRID)
    {
        # Check if the primary group of the object is protected.
        # If so, return with the distinguished name of the primary group.
        If ($Script:ProtGroupRIDs.ContainsKey($PriGroupRID))
        {Return $Script:ProtGroupRIDs[$PriGroupRID]}
    }
    ForEach ($DirectGroupDN In $DirectGroups)
    {
        # Check each direct group membership of the object.
        # Avoid error if distinguished name contains the "/" character.
        $DirectGroupDN = $DirectGroupDN -Replace "/", "\/"
        # If the group is protected, return with the distinguished name of the group.
        If ($Script:ProtGrps.ContainsKey($DirectGroupDN))
        {Return $DirectGroupDN}
    }
    # It should never happen that the object belongs to no protected groups, since
    # we already filtered on membership in a protected group. But we should flag
    # if this ever happens.
    Return "<none>"
}

$RootDSE = [System.DirectoryServices.DirectoryEntry]([ADSI]"LDAP://RootDSE")
$ConfigNC = $RootDSE.Get("configurationNamingContext")

# Setup DirectorySearcher object.
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.PageSize = 800
$Searcher.SearchScope = "subtree"
# Attributes to be retrieved.
$Searcher.PropertiesToLoad.Add("distinguishedName") > $Null
$Searcher.PropertiesToLoad.Add("objectSID") > $Null
$Searcher.PropertiesToLoad.Add("sAMAccountName") > $Null
$Searcher.PropertiesToLoad.Add("memberOf") > $Null
$Searcher.PropertiesToLoad.Add("objectClass") > $Null
$Searcher.PropertiesToLoad.Add("adminCount") > $Null
$Searcher.PropertiesToLoad.Add("primaryGroupID") > $Null

# Retrieve the forest.
$Forest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest()

"Forest: " + $Forest.Name
"-----"

# Enumerate all domains in the forest.
ForEach ($Domain In $Forest.Domains)
{
    "Domain: " + $Domain.Name

    # Initialize totals for the domain.
    $NumDefProtGroups = 0
    $NumNestedProtGroups = 0
    $NumInhDisabledGroups = 0
    $NumInhDisabledUsers = 0
    $NumInhDisabledComputers = 0
    $NumOrphGroups = 0
    $NumOrphUsers = 0
    $NumOrphComputers = 0

    # Default groups protected in all versions of Windows Server.
    $DefProtectedRIDs = @(544, 512, 518, 519)
    # Hash table of all protected group RIDs.
    $ProtGroupRIDs = @{}

    # Filter on all users, computers, and groups. Clauses will be added to only include
    # members of any protected groups, including due to group nesting.
    # This will be used to find all protected objects.
    # Both user and computer objects have class "user".
    $Filter1 = "(&(|(objectClass=user)(objectCategory=group))(|"

    # A similar filter, but clauses will be added to exclude
    # members of any protected groups, including due to group nesting.
    # This will be used to find all objects not protected, but with inheritance disabled.
    $Filter2 = "(&(|(objectClass=user)(objectCategory=group))"

    # Retrieve distinguished name of the domain.
    $DN = ($Domain.GetDirectoryEntry()).distinguishedName

    # Locate the domain controller with the Primary Domain Controller Emulator FSMO role.
    # Determine operating system, SP level, and HotFix of PDCe.
    $PDCOwner = $Domain.PDCRoleOwner
    $PDCDN = ($PDCOwner.GetDirectoryEntry()).serverReference
    $PDCe = [ADSI]"LDAP://$PDCDN"
    $OS = $PDCe.operatingSystem
    $OSVer = $PDCe.operatingSystemVersion
    $SP = $PDCe.OperatingSystemServicePack
    If ($SP)
    {
        "  PDC Emulator FSMO Role Owner: " + $PDCe.dNSHostName + " ($OS $SP)"
    }
    Else
    {
        "  PDC Emulator FSMO Role Owner: " + $PDCe.dNSHostName + " ($OS)"
    }
    $HF = $PDCe.OperatingSystemHotFix

    # Indicate if the dSHeuristics attribute applies. This is determined by the
    # operating system of the PDC Emulator.
    $DSHeurApplies = $False

    # Populate array of RID values of default protected groups in this domain.
    # The operating system of the PDC Emulator determines which users and groups
    # are protected by default.
    If ($OSVer -Like "5.0 *")
    {
        # Windows 2000.
        If (($SP -eq "Service Pack 4") -or ($HF -eq "327825"))
        {
            $DSHeurApplies = $True
            # Cert Publishers
            $DefProtectedRIDs = $DefProtectedRIDs + 517
            # Replicator
            $DefProtectedRIDs = $DefProtectedRIDs + 552
            # Administrator
            $DefProtectedRIDs = $DefProtectedRIDs + 500
            # krbtgt
            $DefProtectedRIDs = $DefProtectedRIDs + 502
        }
    }
    If ($OSVer -Like "5.2 *")
    {
        # Windows Server 2003.
        $DSHeurApplies = $True
        If (($SP -eq "Service Pack 1") -or ($SP -eq "Service Pack 2"))
        {
            # Replicator
            $DefProtectedRIDs = $DefProtectedRIDs + 552
            # Administrator
            $DefProtectedRIDs = $DefProtectedRIDs + 500
            # krbtgt
            $DefProtectedRIDs = $DefProtectedRIDs + 502
        }
        Else
        {
            # Cert Publishers
            $DefProtectedRIDs = $DefProtectedRIDs + 517
            # Replicator
            $DefProtectedRIDs = $DefProtectedRIDs + 552
            # Administrator
            $DefProtectedRIDs = $DefProtectedRIDs + 500
            # krbtgt
            $DefProtectedRIDs = $DefProtectedRIDs + 502
        }
    }
    If (($OSVer -Like "6.0 *") -or ($OSVer -Like "6.1 *") -or ($OSVer -Like "6.2 *") `
        -or ($OSVer -Like "6.3 *") -or ($OSVer -Like "10.0 *"))
    {
        # Windows Server 2008 or Windows Server 2008 R2 or Windows Server 2012
        # or Windows Server 2012 R2 or Windows Server 2016.
        $DSHeurApplies = $True
        # Domain Controllers
        $DefProtectedRIDs = $DefProtectedRIDs + 516
        # Replicator
        $DefProtectedRIDs = $DefProtectedRIDs + 552
        # Administrator
        $DefProtectedRIDs = $DefProtectedRIDs + 500
        # krbtgt
        $DefProtectedRIDs = $DefProtectedRIDs + 502
        # Read-only Domain Controllers
        $DefProtectedRIDs = $DefProtectedRIDs + 521
    }

    If ($DSHeurApplies -eq $True)
    {
        $DS = "cn=Directory Service,cn=Windows NT,cn=Services,$ConfigNC"
        # The dSHeuristics attribute of the "cn=Directory Service" object is a string
        # value where each character represents a different setting. The 16th character
        # is a hexadecimal that determines which of the default Operator groups are
        # not protected. This applies to all domains in the forest.
        # The use of psbase is required to support PowerShell V1.
        $DSHeur = ([ADSI]"LDAP://$DS").psbase.Properties.dSHeuristics
        # Pad the value so there are at least 16 characters. Then consider only
        # the 16th character.
        $DSChar = $("$DSHeur" + "0000000000000000").Substring(15, 1)
        # Interpret the character as a hexadecimal digit.
        $Groups = "0x" + $DSChar
        If ($Groups -band 0x1) {"  Account Operators not protected"}
        Else{$DefProtectedRIDs = $DefProtectedRIDs + 548}
        If ($Groups -band 0x2) {"  Server Operators not protected"}
        Else{$DefProtectedRIDs = $DefProtectedRIDs + 549}
        If ($Groups -band 0x4) {"  Print Operators not protected"}
        Else{$DefProtectedRIDs = $DefProtectedRIDs + 550}
        If ($Groups -band 0x8) {"  Backup Operators not protected"}
        Else{$DefProtectedRIDs = $DefProtectedRIDs + 551}
    }
    "-----"

    # Hash table of protected groups in this domain.
    # Script must keep track of all nested groups of protected groups.
    $ProtGrps = @{}

    # The domain is the base of the search.
    $Searcher.SearchRoot = "LDAP://$DN"

    # Filter on all groups.
    $Searcher.Filter = "(objectCategory=Group)"

    "Protected groups (indented to show nesting)"
    "Group DN (NT name, default/nested, inheritance)"

    $Groups = $Searcher.FindAll()
    ForEach ($Group In $Groups)
    {
        # Retrieve the RID of the group from objectSID.
        $SID = $Group.Properties.Item("objectSID")[0]
        $k = $SID.Count
        $RID = [Int32]$SID[$k - 4] + (256 * [int32]$SID[$k - 3]) `
            + (256 * 256 * [Int32]$SID[$k - 2]) `
            + (256 * 256 * 256 * [Int32]$SID[$k - 1])
        If ($DefProtectedRIDs -Contains $RID)
        {
            # Default protected group.
            $GroupDN = $Group.Properties.Item("distinguishedName")[0]
            # Avoid error if distinguished name contains the "/" character.
            $GroupDN = $GroupDN -Replace "/", "\/"
            $GroupNTName = $Group.Properties.Item("sAMAccountName")
            # Determine if inheritance enabled for this object.
            $Entry = $Group.GetDirectoryEntry()
            # The use of psbase is required to support PowerShell V1.
            $GroupInherit = $Entry.psbase.ObjectSecurity.AreAccessRulesProtected
            If ($GroupInherit -eq "True") {$Inherit = "Inheritance disabled"}
            Else {$Inherit = "Inheritance enabled"}
            "  $GroupDN ($GroupNTName, default, $Inherit)"
            $NumDefProtGroups = $NumDefProtGroups + 1
            # Filter1 on objects that are members of the protected group.
            # Also objects where this group is the primary.
            $Filter1 = $Filter1 + "(memberOf=" + $GroupDN `
                + ")(primaryGroupID=$RID)"
            # Filter2 on objects that are not members of the protected group.
            # Also objects where this group is not the primary.
            $Filter2 = $Filter2 + "(!(memberOf=" + $GroupDN `
                + "))(!(primaryGroupID=$RID))"
            # Add to the hash tables of protected groups.
            $ProtGrps.Add($GroupDN, $RID)
            $ProtGroupRIDs.Add($RID, $GroupDN)
            # Use recursive function to consider all nested groups.
            GetNestedGroups $GroupDN "  "
        }
    }
    "-----"

    $Filter1 = $Filter1 + "))"
    $Filter2 = $Filter2 + ")"

    # Filter on all users, computers, and groups that are members of a protected group.
    # We are looking for all such objects with inheritance disabled, but we cannot
    # filter on that.
    $Searcher.Filter = $Filter1

    "Protected security objects (excluding default protected groups and users)"
    "Object DN (class, NT name, adminCount, inheritance)"
    "    Protected because of membership in"

    $SecObjects = $Searcher.FindAll()
    ForEach ($SecObject In $SecObjects)
    {
        # Determine if inheritance enabled for this object.
        $Entry = $SecObject.GetDirectoryEntry()
        # The use of psbase is required to support PowerShell V1.
        $ObjInherit = $Entry.psbase.ObjectSecurity.AreAccessRulesProtected
        If ($ObjInherit -eq "True") {$Inherit = "Inheritance disabled"}
        Else {$Inherit = "Inheritance enabled"}
        # Retrieve the RID of the object from objectSID.
        $SID = $SecObject.Properties.Item("objectSID")[0]
        $k = $SID.Count
        $RID = [Int32]$SID[$k - 4] + (256 * [int32]$SID[$k - 3]) `
            + (256 * 256 * [Int32]$SID[$k - 2]) `
            + (256 * 256 * 256 * [Int32]$SID[$k - 1])
        # Default protected objects are excluded.
        If ($DefProtectedRIDs -NotContains $RID)
        {
            $ObjectDN = $SecObject.Properties.Item("distinguishedName")
            # Avoid error if distinguished name contains the "/" character.
            $ObjectDN = $ObjectDN -Replace "/", "\/"
            $ObjectNTName = $SecObject.Properties.Item("sAMAccountName")
            $ObjectAdmCount = $SecObject.Properties.Item("adminCount")[0]
            If ($ObjectAdmCount -eq $Null) {$ObjectAdmCount = "<not set>"}
            $PriGroupRID = $SecObject.Properties.Item("primaryGroupID")[0]
            $ObjGroups = $SecObject.Properties.Item("memberOf")
            # Retrieve a group membership that causes the object to be protected.
            $ProtGrpDN = GetProtGroup $ObjGroups $PriGroupRID
            $ObjectClass = $SecObject.Properties.Item("objectClass")
            # Every object has at least two classes in the array. The script needs to
            # retrieve the most specific, which will be the last entry in the array.
            $Class = $ObjectClass[$ObjectClass.Count - 1]
            # Update totals by class.
            Switch ($Class)
            {
                "user" {$NumInhDisabledUsers = $NumInhDisabledUsers + 1}
                "computer" {$NumInhDisabledComputers = $NumInhDisabledComputers + 1}
                "group" {$NumInhDisabledGroups = $NumInhDisabledGroups + 1}
            }
            "  $ObjectDN ($Class, $ObjectNTName, $ObjectAdmCount, $Inherit)"
            "    $ProtGrpDN"
        }
    }
    "-----"

    # Filter on all security objects that are not members of a protected group.
    # Again, we cannot filter on whether inheritance is disabled.
    $Searcher.Filter = $Filter2

    "Orphaned objects (not in a protected group" `
        + ", but either inheritance disabled or adminCount is 1)"
    "Object DN (class, NT name, adminCount, inheritance)"

    $Orphans = $Searcher.FindAll()
    ForEach ($Orphan In $Orphans)
    {
        $ObjectCount = $Orphan.Properties.Item("adminCount")[0]
        If ($ObjectCount -eq $Null) {$ObjectCount = "<not set>"}
        # Determine if inheritance enabled for this object.
        $Entry = $Orphan.GetDirectoryEntry()
        # The use of psbase is required to support PowerShell V1.
        $ObjectInherit = $Entry.psbase.ObjectSecurity.AreAccessRulesProtected
        If ($ObjectInherit -eq "True") {$Inherit = "Inheritance disabled"}
        Else {$Inherit = "Inheritance enabled"}
        If (($ObjectCount -eq 1) -or ($Inherit -eq "Inheritance disabled"))
        {
            # Orphaned object.
            $ObjectDN = $Orphan.Properties.Item("distinguishedName")
            # Avoid error if distinguished name contains the "/" character.
            $ObjectDN = $ObjectDN -Replace "/", "\/"
            $ObjectNTName = $Orphan.Properties.Item("sAMAccountName")
            $ObjectClass = $Orphan.Properties.Item("objectClass")
            # Every object has at least two classes in the array. The script needs to
            # retrieve the most specific, which will be the last entry in the array.
            $Class = $ObjectClass[$ObjectClass.Count - 1] 
            # Retrieve the RID of the object from objectSID.
            $SID = $Orphan.Properties.Item("objectSID")[0]
            $k = $SID.Count
            $RID = [Int32]$SID[$k - 4] + (256 * [int32]$SID[$k - 3]) `
                + (256 * 256 * [Int32]$SID[$k - 2]) `
                + (256 * 256 * 256 * [Int32]$SID[$k - 1])
            # Default protected objects are excluded.
            If ($DefProtectedRIDs -NotContains $RID)
            {
                # Update totals by class.
                Switch ($Class)
                {
                    "user" {$NumOrphUsers = $NumOrphUsers + 1}
                    "computer" {$NumOrphComputers = $NumOrphComputers + 1}
                    "group" {$NumOrphGroups = $NumOrphGroups + 1}
                }
                "  $ObjectDN ($Class, $ObjectNTName, $ObjectCount, $Inherit)"
            }
        }
    }
    "-----"
    # Format the totals.
    $NumProtGroups = $NumDefProtGroups + $NumNestedProtGroups
    $NumInhDisabled = $NumInhDisabledGroups + $NumInhDisabledUsers + $NumInhDisabledComputers
    $NumOrphaned = $NumOrphGroups + $NumOrphUsers + $NumOrphComputers
    $Total = $NumProtGroups + $NumInhDisabled + $NumOrphaned
    $NTotal = '{0:n0}' -f $Total
    $Max = $NTotal.Length
    $NGroups = ('{0:n0}' -f $NumProtGroups).PadLeft($Max, " ")
    $NDefGroups = ('{0:n0}' -f $NumDefProtGroups).PadLeft($Max, " ")
    $NNestedGroups = ('{0:n0}' -f $NumNestedProtGroups).PadLeft($Max, " ")
    $NIDGroups = ('{0:n0}' -f $NumInhDisabledGroups).PadLeft($Max, " ")
    $NIDUsers = ('{0:n0}' -f $NumInhDisabledUsers).PadLeft($Max, " ")
    $NIDComputers = ('{0:n0}' -f $NumInhDisabledComputers).PadLeft($Max, " ")
    $NIDObjs = ('{0:n0}' -f $NumInhDisabled).PadLeft($Max, " ")
    $NOGroups = ('{0:n0}' -f $NumOrphGroups).PadLeft($Max, " ")
    $NOUsers = ('{0:n0}' -f $NumOrphUsers).PadLeft($Max, " ")
    $NOComputers = ('{0:n0}' -f $NumOrphComputers).PadLeft($Max, " ")
    $NOrphaned = ('{0:n0}' -f $NumOrphaned).PadLeft($Max, " ")
    "Totals:"
    "  Protected Groups:        $NGroups"
    "    Default:               $NDefGroups"
    "    Nested:                $NNestedGroups"
    "  Protected Objects:       $NIDObjs"
    "    Groups:                $NIDGroups"
    "    Users:                 $NIDUsers"
    "    Computers:             $NIDComputers"
    "  Total Orphaned Objects:  $NOrphaned"
    "    Groups:                $NOGroups"
    "    Users:                 $NOUsers"
    "    Computers:             $NOComputers"
    "-----"
}