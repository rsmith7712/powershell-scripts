   <#	
	.NOTES
	===========================================================================
	 Created on:   	1/30/2017 1:15 PM
	 Created by:   	user22
	 Organization: 	Domain, Inc.
	 Filename:     	edit-enableadal.ps1
	===========================================================================
	.DESCRIPTION
		Edits the regkey associated with single sign on.  This will allow single sign on
#>


$regpathv16 = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity"
$regpathv15 = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Common\Identity"
$regname = "EnableADAL"
$regvalue = "1"

if(!(Test-Path $regpathv15))
{
    New-Item -Path $regpathv15 -Force
    New-ItemProperty -Path $regpathv15 -Name $regname -Value $regvalue -PropertyType DWORD -Force
}
else
{
    New-ItemProperty -Path $regpathv15 -Name $regname -Value $regvalue -PropertyType DWORD -Force
}

if(!(Test-Path $regpathv16))
{
    New-Item -Path $regpathv16 -Force
    New-ItemProperty -Path $regpathv16 -Name $regname -Value $regvalue -PropertyType DWORD -Force
}
else
{
    New-ItemProperty -Path $regpathv16 -Name $regname -Value $regvalue -PropertyType DWORD -Force
}