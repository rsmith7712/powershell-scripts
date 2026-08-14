Import-Module ActiveDirectory

$userlist = get-aduser -SearchBase "ou=corporate accounts,dc=domain,dc=com" -Filter {Enabled -ne "False"} | Select samaccountname
$userlist += get-aduser -SearchBase "ou=External Accounts,ou=domain services,dc=domain,dc=com" -Filter {Enabled -ne "False"} | Select samaccountname
$userlist += get-aduser -SearchBase "ou=Remote Accounts,dc=domain,dc=com" -Filter {Enabled -ne "False"} | Select samaccountname

$grouplist = get-adgroupmember -Identity "cn=*all company employees,ou=Corporate DL,ou=Distribution,ou=Group Accounts,dc=domain,dc=com" | select samaccountname

#$userlist | ?{$grouplist -notcontains $_}

$output = @()

ForEach($user in $userlist)
{
    If(!($grouplist.Contains($User))){
        $output += $user
    }
}
$output | Out-File C:\userlist.txt