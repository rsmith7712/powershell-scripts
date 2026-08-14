<#
.SYNOPSIS
  Function used to get the TKT password for a stores TKT account.

.EXAMPLE
  Get_TKT_Pass "1003"

#>

Function Get_TKT_Pass($UFO_NUMBER)
{
	$cubed = [Math]::Pow($UFO_NUMBER, 3)
	$hexnum = [Convert]::ToString($cubed, 16)
	$tkt_password = $hexnum.ToUpper()
  return $tkt_password
}