$stamp = get-date -Format yyyy.MM.dd-HH.mm.ss
$Script:Logfile = "C:\temp\FILENAME_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, OU, License Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}