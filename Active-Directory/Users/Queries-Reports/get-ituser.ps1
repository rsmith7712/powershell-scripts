$credential = Get-Credential domain\pcadmin4

$array = @()

$firstname = Get-ADUser -Credential $credential -SearchBase "OU=Information Systems,OU=Corporate Accounts,DC=Domain,DC=com" -Filter * | select -Property givenname
$lastname = Get-ADUser -Credential $credential -SearchBase "OU=Information Systems,OU=Corporate Accounts,DC=Domain,DC=com" -Filter * | select -Property surname

# NOTE: the original author left this script incomplete here — the line that combined
# $firstname/$lastname into $name was truncated mid-statement ("$name = foreach ($")
# and never finished. Truncated rather than guessing the intended logic.