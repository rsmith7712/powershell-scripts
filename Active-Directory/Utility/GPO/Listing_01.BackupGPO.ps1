filter Do-GPOBackup
{
  $GPM = New-Object -comobject GPMgmt.GPM
  $const = $GPM.GetConstants()
  $GPMDomain = $GPM.GetDomain($_.Domain, "", $Const.UseAnyDC)
  $GPO = $GPMDomain.GetGPO($_.GPOGUID)
  $GPMResult = $GPO.Backup("C:\", $_.Description)

  Write-host "Backed up GPO $($_.GPOName)"
}





