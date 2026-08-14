# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Get-Certificate.ps1

.DESCRIPTION
    Retrieves certificates from a specified certificate store and location on one or more computers.

.FUNCTIONALITY
    Retrieves certificates from a computer's store.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Get-Certificate  {	
	[cmdletbinding()]	
	Param (		
		[parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]		
		[Alias('PSComputername','__Server','IPAddress')]		
		[string[]]$Computername =  $env:COMPUTERNAME,	
        [parameter()]	
		[System.Security.Cryptography.X509Certificates.StoreName]$StoreName = 'My',		
        [parameter()]
		[System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation  = 'LocalMachine',
        [parameter()]
        [switch]$IncludeArchive,
        [parameter()]
        [string]$Issuer,
        [parameter()]
        [string]$Subject,
        [parameter()]
        [string]$Thumbprint
	
	)	
    Begin {
		$WhereList = New-Object System.Collections.ArrayList
		If ($PSBoundParameters.ContainsKey('Issuer')) {
			[void]$WhereList.Add('$_.Issuer -LIKE $Issuer')
		}
		If ($PSBoundParameters.ContainsKey('Subject')) {
			[void]$WhereList.Add('$_.Subject -LIKE $Subject')
		}
		If ($PSBoundParameters.ContainsKey('Thumbprint')) {
			[void]$WhereList.Add('$_.Thumbprint -LIKE $Thumbprint')
		}
    If ($WhereList.count -gt 0) {
		    $Where = [scriptblock]::Create($WhereList -join ' -AND ')
		    Write-Debug "WhereBlock: $($Where)"
    }
    }
	Process  {		
		ForEach  ($Computer in  $Computername) {			
			Try  {				
				Write-Verbose  ("Connecting to \\{0}\{1}\{2}" -f $Computer,$StoreLocation,$StoreName)				
				$CertStore  = New-Object  System.Security.Cryptography.X509Certificates.X509Store  -ArgumentList "\\$($Computer)\$($StoreName)", $StoreLocation				
        		If ($PSBoundParameters.ContainsKey('IncludeArchive')) {
                    $Flags = [System.Security.Cryptography.X509Certificates.OpenFlags]'ReadOnly','IncludeArchived'
                } Else {
                    $Flags = [System.Security.Cryptography.X509Certificates.OpenFlags]'ReadOnly'
                }		                
				$CertStore.Open($Flags)																	
    			If ($WhereList.count -gt 0) {
                    $Certificates = $CertStore.Certificates | Where $Where
                } Else {
                    $Certificates = $CertStore.Certificates
                }	
                $Certificates | ForEach {							
					$Days = Switch ((New-TimeSpan  -End $_.NotAfter).Days)  {								
						{$_ -gt 0} {$_}								
						Default {'Expired'}								
					}							
					$_ | Add-Member -MemberType  NoteProperty -Name  ExpiresIn -Value  $Days -PassThru | 
                        Add-Member -MemberType NoteProperty -Name Computername -Value $Computer -PassThru														
				}															
			} Catch  {				
				Write-Warning  "$($Computer): $_"				
			}			
		}		
	}	
}



$Servers = Import-CSV "\\SERVER\SHARE\...\FullServiceList.csv"
$Servers = $Servers.ServerName

$report = "\\SERVER\SHARE\...\CertCheck.CSV"
If(Test-Path $report)
{
    Remove-Item $report -force
    New-Item $report -Type File
}

ForEach($Server in $Servers){
    $Certs = Get-Certificate -Computername $Server -StoreName My -StoreLocation LocalMachine | Select-Object Subject,ExpiresIn,NotAfter
    Add-Content $Report "$Server"
    Add-Content $Report "$Certs.Subject,$Certs.ExpiresIn,$Certs.NotAfter"
}