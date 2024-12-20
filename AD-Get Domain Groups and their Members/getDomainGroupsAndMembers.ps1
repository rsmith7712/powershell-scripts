$list = @()
$Groups = get-adgroup -filter * -SearchBase "OU=,DC=,DC="
foreach ($Group in $Groups){
    $members = get-adgroupmember -identity $group
    foreach ($member in $members){
        if($member.objectClass -eq "User" -or "Group"){
    
            $item = new-object PSObject
            $item | Add-member -name 'Group' -value $group.name -MemberType NoteProperty
            $item | Add-member -name 'Member' -value $member.samaccountname -MemberType NoteProperty
            $item | Add-member -name 'Type' -value $member.objectClass -MemberType NoteProperty
            $list += $item
        }
    }

}
    $list | export-csv "d:\GroupsandUsers.csv" -NoTypeInformation