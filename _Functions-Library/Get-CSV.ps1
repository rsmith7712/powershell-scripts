$csvInPath = "C:\temp\Get-ActiveSessions_testies123.csv"
$csvIn = Import-Csv -Path $csvInPath
$csvIn | ForEach-Object{Write-Host $_}