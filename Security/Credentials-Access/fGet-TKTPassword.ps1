Function Get-TKTpass($store)
{
	$cubed = [Math]::Pow($store, 3)
	$hexNum = [Convert]::ToString($cubed, 16)
	$tktPassword = $hexNum.ToUpper()
    $output = "DOMAIN\$([string]$store)TKT Password : $($tktPassword)"
    return $output
}# =====================[END FUNCTION]=====================
Clear-Host
Write-Host "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=" -ForegroundColor Cyan
Write-Host "   Domain Ticketing Account Password Decoder Tool  " -ForegroundColor White
Write-Host "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=" -ForegroundColor Cyan
Write-Host ""
[int]$store = Read-Host "Enter UFO_NUMBER"
Write-Host ""
$pw = Get-TKTpass -store $store
Write-Host $pw -ForegroundColor Green
Write-Host "Press any key to Exit..."
[void]($Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'))
