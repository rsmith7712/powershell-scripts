# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
    Export-DistributionGroups.ps1

.DESCRIPTION
    Exports all Exchange distribution groups with their attributes and membership to a CSV.

.FUNCTIONALITY
    Exports distribution groups and members to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# CSV file export path
$Csvfile = "C:\temp\Export-DistributionGroups.csv"

# Get all distribution groups
$Groups = Get-DistributionGroup -ResultSize Unlimited

# Loop through distribution groups
$Groups | ForEach-Object {

    $GroupDN = $_.DistinguishedName
    $DisplayName = $_.DisplayName
    $PrimarySmtpAddress = $_.PrimarySmtpAddress
    $SecondarySmtpAddress = $_.EmailAddresses | Where-Object {$_ -clike "smtp*"} | ForEach-Object {$_ -replace "smtp:",""}
    $GroupType = $_.GroupType
    $RecipientType = $_.RecipientType
    $Members = Get-DistributionGroupMember $GroupDN -ResultSize Unlimited
    $ManagedBy = $_.ManagedBy
    $Alias = $_.Alias
    $HiddenFromAddressLists = $_.HiddenFromAddressListsEnabled
    $MemberJoinRestriction = $_.MemberJoinRestriction
    $MemberDepartRestriction = $_.MemberDepartRestriction
    $RequireSenderAuthenticationEnabled = $_.RequireSenderAuthenticationEnabled
    $AcceptMessagesOnlyFrom = $_.AcceptMessagesOnlyFrom
    $GrantSendOnBehalfTo = $_.GrantSendOnBehalfTo
    $Notes = (Get-Group $GroupDN)

    # Create objects
    [PSCustomObject]@{
        DisplayName                        = $DisplayName
        PrimarySmtpAddress                 = $PrimarySmtpAddress
        SecondaryStmpAddress               = ($SecondarySmtpAddress -join ',')
        Alias                              = $Alias
        GroupType                          = $GroupType
        RecipientType                      = $RecipientType
        Members                            = ($Members.Name -join ',')
        MembersPrimarySmtpAddress          = ($Members.PrimarySmtpAddress -join ',')
        ManagedBy                          = $ManagedBy.Name
        HiddenFromAddressLists             = $HiddenFromAddressLists
        MemberJoinRestriction              = $MemberJoinRestriction
        MemberDepartRestriction            = $MemberDepartRestriction
        RequireSenderAuthenticationEnabled = $RequireSenderAuthenticationEnabled
        AcceptMessagesOnlyFrom             = ($AcceptMessagesOnlyFrom.Name -join ',')
        GrantSendOnBehalfTo                = $GrantSendOnBehalfTo.Name
        Notes                              = $Notes.Notes
    }

# Export report to CSV file
} | Sort-Object DisplayName | Export-CSV -Path $Csvfile -NoTypeInformation -Encoding UTF8 #-Delimiter ";"