# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Check_ScoreCard_Services_v1.ps1

.DESCRIPTION
    		- Query specified server service status and availability -- (if applicable)
    		- Query each server for their system uptime (since their last reboot)
    		- Post HTML report on file share, and separately...
    		- Email HTML report to specific addresses

.FUNCTIONALITY
    		- Query specified server service status and availability -- (if applicable)
    		- Query each server for their system uptime (since their last reboot)
    		- Post HTML report on file share, and separately...
    		- Email HTML report to specific addresses

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Import AD Module
Import-Module ActiveDirectory;
Write-Host "AD Module Imported";

# Enable PowerShell Remote Sessions
Enable-PSRemoting -Force;
Write-Host "PSRemoting Enabled";

# Set Execution Policy to Unrestricted
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Write-Host "Execution Policy Set";

############################################# Define Servers & Services Variables

#### S1 -- Family: 
$Server1List_DMZ_IIS1 = Get-Content "\\SERVER\SHARE\...\Server1_DMZ-IIS1.txt"
$Services1List_DMZ_IIS1 = Get-Content "\\SERVER\SHARE\...\Services1_DMZ-IIS1.txt"

$Server1List_DOMAINSQL2 = Get-Content "\\SERVER\SHARE\...\Server1_DOMAINSQL2.txt"
$Services1List_DOMAINSQL2 = Get-Content "\\SERVER\SHARE\...\Services1_DOMAINSQL2.txt"

$Server1List_SRV_GD3_SQL1 = Get-Content "\\SERVER\SHARE\...\Server1_srv.txt"
$Services1List_SRV_GD3_SQL1 = Get-Content "\\SERVER\SHARE\...\Services1_srv.txt"

$Server1List_SRV_IIS1 = Get-Content "\\SERVER\SHARE\...\Server1_srv.txt"
$Services1List_SRV_IIS1 = Get-Content "\\SERVER\SHARE\...\Services1_srv.txt"

#### S2 -- Family: DONATION MANAGER
$Server2List_DMZ_S1_IIS1 = Get-Content "\\SERVER\SHARE\...\Server2_DMZ-S1-IIS1.txt"
$Services2List_DMZ_S1_IIS1 = Get-Content "\\SERVER\SHARE\...\Services2_DMZ-S1-IIS1.txt"

$Server2List_DMZ_S1_IIS2 = Get-Content "\\SERVER\SHARE\...\Server2_DMZ-S1-IIS2.txt"
$Services2List_DMZ_S1_IIS2 = Get-Content "\\SERVER\SHARE\...\Services2_DMZ-S1-IIS2.txt"

$Server2List_DMZ_S1_IIS3 = Get-Content "\\SERVER\SHARE\...\Server2_DMZ-S1-IIS3.txt"
$Services2List_DMZ_S1_IIS3 = Get-Content "\\SERVER\SHARE\...\Services2_DMZ-S1-IIS3.txt"

$Server2List_DMZ_S1_IIS4 = Get-Content "\\SERVER\SHARE\...\Server2_DMZ-S1-IIS4.txt"
$Services2List_DMZ_S1_IIS4 = Get-Content "\\SERVER\SHARE\...\Services2_DMZ-S1-IIS4.txt"

$Server2List_DMZ_S1_IIS5 = Get-Content "\\SERVER\SHARE\...\Server2_DMZ-S1-IIS5.txt"
$Services2List_DMZ_S1_IIS5 = Get-Content "\\SERVER\SHARE\...\Services2_DMZ-S1-IIS5.txt"

$Server2List_DMZ_S1_MAP1 = Get-Content "\\SERVER\SHARE\...\Server2_DMZ-S1-MAP1.txt"
$Services2List_DMZ_S1_MAP1 = Get-Content "\\SERVER\SHARE\...\Services2_DMZ-S1-MAP1.txt"

$Server2List_DMZ_S1_MAP2 = Get-Content "\\SERVER\SHARE\...\Server2_DMZ-S1-MAP2.txt"
$Services2List_DMZ_S1_MAP2 = Get-Content "\\SERVER\SHARE\...\Services2_DMZ-S1-MAP2.txt"

$Server2List_DMZ_S1_MAP3 = Get-Content "\\SERVER\SHARE\...\Server2_DMZ-S1-MAP3.txt"
$Services2List_DMZ_S1_MAP3 = Get-Content "\\SERVER\SHARE\...\Services2_DMZ-S1-MAP3.txt"

$Server2List_DMZ_S1_MAP4 = Get-Content "\\SERVER\SHARE\...\Server2_DMZ-S1-MAP4.txt"
$Services2List_DMZ_S1_MAP4 = Get-Content "\\SERVER\SHARE\...\Services2_DMZ-S1-MAP4.txt"

$Server2List_DMZ_S1_MAP5 = Get-Content "\\SERVER\SHARE\...\Server2_DMZ-S1-MAP5.txt"
$Services2List_DMZ_S1_MAP5 = Get-Content "\\SERVER\SHARE\...\Services2_DMZ-S1-MAP5.txt"

$Server2List_PD0_ENT_SRS1 = Get-Content "\\SERVER\SHARE\...\Server2_srv.txt"
$Services2List_PD0_ENT_SRS1 = Get-Content "\\SERVER\SHARE\...\Services2_srv.txt"

$Server2List_PS0_DM_SCH1 = Get-Content "\\SERVER\SHARE\...\Server2_SRV-DM-SCH1"
$Services2List_PS0_DM_SCH1 = Get-Content "\\SERVER\SHARE\...\Services2_SRV-DM-SCH1.txt"

$Server2List_SRV_GD3_SQL2 = Get-Content "\\SERVER\SHARE\...\Server2_srv.txt"
$Services2List_SRV_GD3_SQL2 = Get-Content "\\SERVER\SHARE\...\Services2_srv.txt"

#### S3 -- Family: KRONOS
$Server3List_SRV_KROAPP1 = Get-Content "\\SERVER\SHARE\...\Server3_SRV_KROAPP1.txt"
$Services3List_SRV_KROAPP1 = Get-Content "\\SERVER\SHARE\...\Services3_SRV_KROAPP1.txt"

$Server3List_SRV_KROAPP2 = Get-Content "\\SERVER\SHARE\...\Server3_SRV_KROAPP2.txt"
$Services3List_SRV_KROAPP2 = Get-Content "\\SERVER\SHARE\...\Services3_SRV_KROAPP2.txt"

$Server3List_SRV_KROBGP1 = Get-Content "\\SERVER\SHARE\...\Server3_SRV_KROBGP1.txt"
$Services3List_SRV_KROBGP1 = Get-Content "\\SERVER\SHARE\...\Services3_SRV_KROBGP1.txt"

$Server3List_SRV_KRODB1 = Get-Content "\\SERVER\SHARE\...\Server3_SRV_KRODB1.txt"
$Services3List_SRV_KRODB1 = Get-Content "\\SERVER\SHARE\...\Services3_SRV_KRODB1.txt"

$Server3List_SRV_KROWDM1 = Get-Content "\\SERVER\SHARE\...\Server3_SRV_KROWDM1.txt"
$Services3List_SRV_KROWDM1 = Get-Content "\\SERVER\SHARE\...\Services3_SRV_KROWDM1.txt"

$Server3List_SRV_KROWWIM1 = Get-Content "\\SERVER\SHARE\...\Server3_SRV_KROWWIM1.txt"
$Services3List_SRV_KROWWIM1 = Get-Content "\\SERVER\SHARE\...\Services3_SRV_KROWWIM1.txt"

#### S4 -- Family: TRUCKING
$Server4List_DMZ_S2_D2L = Get-Content "\\SERVER\SHARE\...\Server4_DMZ-S2-D2L.txt"
$Services4List_DMZ_S2_D2L = Get-Content "\\SERVER\SHARE\...\Services4_DMZ-S2-D2L.txt"

$Server4List_DMZ_S2_IIS1 = Get-Content "\\SERVER\SHARE\...\Server4_DMZ-S2-IIS1.txt"
$Services4List_DMZ_S2_IIS1 = Get-Content "\\SERVER\SHARE\...\Services4_DMZ-S2-IIS1.txt"

$Server4List_DMZ_S2_IIS2 = Get-Content "\\SERVER\SHARE\...\Server4_DMZ-S2-IIS2.txt"
$Services4List_DMZ_S2_IIS2 = Get-Content "\\SERVER\SHARE\...\Services4_DMZ-S2-IIS2.txt"

$Server4List_DMZ_S2_IIS3 = Get-Content "\\SERVER\SHARE\...\Server4_DMZ-S2-IIS3.txt"
$Services4List_DMZ_S2_IIS3 = Get-Content "\\SERVER\SHARE\...\Services4_DMZ-S2-IIS3.txt"

$Server4List_SRV_TS1 = Get-Content "\\SERVER\SHARE\...\Server4_srv.txt"
$Services4List_SRV_TS1 = Get-Content "\\SERVER\SHARE\...\Services4_srv.txt"

$Server4List_SRV_TS2 = Get-Content "\\SERVER\SHARE\...\Server4_srv.txt"
$Services4List_SRV_TS2 = Get-Content "\\SERVER\SHARE\...\Services4_srv.txt"

#### S5 -- Family: DYNAMICS
$Server5List_DOMAINSQL1 = Get-Content "\\SERVER\SHARE\...\Server5_DOMAINSQL1.txt"
$Services5List_DOMAINSQL1 = Get-Content "\\SERVER\SHARE\...\Services5_DOMAINSQL1.txt"

#### S6 -- Family: ORACLE (Linux Servers)
$Server6List_SRVEBSAP1 = Get-Content "\\SERVER\SHARE\...\Server6_SRVEBSAP1.txt"
$Services6List_SRVEBSAP1 = Get-Content "\\SERVER\SHARE\...\Services6_SRVEBSAP1.txt"

$Server6List_SRVEBSAP2 = Get-Content "\\SERVER\SHARE\...\Server6_SRVEBSAP2.txt"
$Services6List_SRVEBSAP2 = Get-Content "\\SERVER\SHARE\...\Services6_SRVEBSAP2.txt"

$Server6List_SRVEBSAPX = Get-Content "\\SERVER\SHARE\...\Server6_SRVEBSAPX.txt"
$Services6List_SRVEBSAPX = Get-Content "\\SERVER\SHARE\...\Services6_SRVEBSAPX.txt"

$Server6List_SRVEBSDB1 = Get-Content "\\SERVER\SHARE\...\Server6_SRVEBSDB1.txt"
$Services6List_SRVEBSDB1 = Get-Content "\\SERVER\SHARE\...\Services6_SRVEBSDB1.txt"

$Server6List_SRV_ORA_NFS1 = Get-Content "\\SERVER\SHARE\...\Server6_nfs1.txt"
$Services6List_SRV_ORA_NFS1 = Get-Content "\\SERVER\SHARE\...\Services6_nfs1.txt"


#### S7 -- Family: FUJITSU
$Server7List_PS0_FSC_FND1 = Get-Content "\\SERVER\SHARE\...\Server7_SRV-FSC-FND1.txt"
$Services7List_PS0_FSC_FND1 = Get-Content "\\SERVER\SHARE\...\Services7_SRV-FSC-FND1.txt"

$Server7List_SRV_FSC_APP3 = Get-Content "\\SERVER\SHARE\...\Server7_srv.txt"
$Services7List_SRV_FSC_APP3 = Get-Content "\\SERVER\SHARE\...\Services7_srv.txt"

$Server7List_SRV_FSC_APP4 = Get-Content "\\SERVER\SHARE\...\Server7_srv.txt"
$Services7List_SRV_FSC_APP4 = Get-Content "\\SERVER\SHARE\...\Services7_srv.txt"

$Server7List_SRV_FSC_DB1 = Get-Content "\\SERVER\SHARE\...\Server7_srv.txt"
$Services7List_SRV_FSC_DB1 = Get-Content "\\SERVER\SHARE\...\Services7_srv.txt"

$Server7List_SRV_RPT_LS1 = Get-Content "\\SERVER\SHARE\...\Server7_srv.txt"
$Services7List_SRV_RPT_LS1 = Get-Content "\\SERVER\SHARE\...\Services7_srv.txt"


#### S8 -- Family: TEXAS
$Server8List_MNCC_MS5 = Get-Content "\\SERVER\SHARE\...\Server8_MNCC-MS5.txt"
$Services8List_MNCC_MS5 = Get-Content "\\SERVER\SHARE\...\Services8_MNCC-MS5.txt"

$Server8List_MNCC_MS6_P = Get-Content "\\SERVER\SHARE\...\Server8_MNCC-MS6-P.txt"
$Services8List_MNCC_MS6_P = Get-Content "\\SERVER\SHARE\...\Services8_MNCC-MS6-P.txt"

$Server8List_MNCC_SM1 = Get-Content "\\SERVER\SHARE\...\Server8_MNCC-SM1.txt"
$Services8List_MNCC_SM1 = Get-Content "\\SERVER\SHARE\...\Services8_MNCC-SM1.txt"


$Server8List_PS1_DM_CH1 = Get-Content "\\SERVER\SHARE\...\Server8_PS1-DM-CH1.txt"
$Services8List_PS1_DM_CH1 = Get-Content "\\SERVER\SHARE\...\Services8_PS1-DM-CH1.txt"


$Server8List_TXCC_CCS1 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-CCS1.txt"
$Services8List_TXCC_CCS1 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-CCS1.txt"

$Server8List_TXCC_CIC1 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-CIC1.txt"
$Services8List_TXCC_CIC1 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-CIC1.txt"

$Server8List_TXCC_CIC2 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-CIC2.txt"
$Services8List_TXCC_CIC2 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-CIC2.txt"

$Server8List_TXCC_Cluster1 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-Cluster1.txt"
$Services8List_TXCC_Cluster1 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-Cluster1.txt"

$Server8List_TXCC_Cluster2 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-Cluster2.txt"
$Services8List_TXCC_Cluster2 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-Cluster2.txt"

$Server8List_TXCC_IIS1 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-IIS1.txt"
$Services8List_TXCC_IIS1 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-IIS1.txt"

$Server8List_TXCC_IIS2 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-IIS2.txt"
$Services8List_TXCC_IIS2 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-IIS2.txt"

$Server8List_TXCC_MS1 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-MS1.txt"
$Services8List_TXCC_MS1 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-MS1.txt"

$Server8List_TXCC_MS2 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-MS2.txt"
$Services8List_TXCC_MS2 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-MS2.txt"

$Server8List_TXCC_SM1 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-SM1.txt"
$Services8List_TXCC_SM1 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-SM1.txt"

$Server8List_TXCC_SQL4 = Get-Content "\\SERVER\SHARE\...\Server8_TXCC-SQL4.txt"
$Services8List_TXCC_SQL4 = Get-Content "\\SERVER\SHARE\...\Services8_TXCC-SQL4.txt"


############################################# Define other variables
$report = "\\SERVER\SHARE\...\ScoreCard_Report.htm" 

$smtphost = "smtpi.example.com" 
$from = "ScoreCard_Status@example.com"
$to = "admin2@example.com"
#$to = "admin2@example.com, DYoung@example.com, SNunes-Ali@example.com"
#$to = "SysAdmins@example.com"
#$to = "admin2@example.com, SysAdmins@example.com, CBlair@example.com"
#$to = "admin2@example.com, SysAdmins@example.com, CBlair@example.com, MHrcek@example.com"



$checkrep = Test-Path "\\SERVER\SHARE\...\ScoreCard_Report.htm"

If ($checkrep -like "True")
	{
		Remove-Item "\\SERVER\SHARE\...\ScoreCard_Report.htm"
	}

New-Item "\\SERVER\SHARE\...\ScoreCard_Report.htm" -Type File

############################################# ADD HTML Content 

Add-Content $report "<html>" 
Add-Content $report "<head>" 
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $report '<title>Scorecard Service Status</title>' 
add-content $report '<STYLE TYPE="text/css">' 
add-content $report  "<!--" 
add-content $report  "td {" 
add-content $report  "font-family: Tahoma;" 
add-content $report  "font-size: 11px;" 
add-content $report  "border-top: 1px solid #999999;" 
add-content $report  "border-right: 1px solid #999999;" 
add-content $report  "border-bottom: 1px solid #999999;" 
add-content $report  "border-left: 1px solid #999999;" 
add-content $report  "padding-top: 0px;" 
add-content $report  "padding-right: 0px;" 
add-content $report  "padding-bottom: 0px;" 
add-content $report  "padding-left: 0px;" 
add-content $report  "}" 
add-content $report  "body {" 
add-content $report  "margin-left: 5px;" 
add-content $report  "margin-top: 5px;" 
add-content $report  "margin-right: 0px;" 
add-content $report  "margin-bottom: 10px;" 
add-content $report  "" 
add-content $report  "table {" 
add-content $report  "border: thin solid #000000;" 
add-content $report  "}" 
add-content $report  "-->" 
add-content $report  "</style>" 
Add-Content $report "</head>" 
Add-Content $report "<body>" 
add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='25' align='center'>"
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>Scorecard Service Status</strong></font>"
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
 
add-content $report  "<table width='100%'>" 
Add-Content $report "<tr bgcolor='IndianRed'>"
Add-Content $report  "<td width='10%' align='center'><B>Server</B></td>"
Add-Content $report  "<td width='10%' align='center'><B>Svr.Uptime</B></td>"
Add-Content $report "<td width='30%' align='center'><B>Service</B></td>" 
Add-Content $report  "<td width='10%' align='center'><B>Status</B></td>" 
Add-Content $report "</tr>"

############################################# FUNCTION - Get-UpTime

function Get-UpTime
{
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
		[Alias("CN")]
		[String]$ComputerName = $Env:ComputerName,
		[Parameter(Position = 1, Mandatory = $false)]
		[Alias("RunAs")]
		[System.Management.Automation.Credential()]
		$Credential = [System.Management.Automation.PSCredential]::Empty
	)
	process
	{
		"Uptime: {1:%d} Days {1:%h} Hours {1:%m} Minutes {1:%s} Seconds" -f $ComputerName,
		(New-TimeSpan -Seconds (Get-WmiObject Win32_PerfFormattedData_PerfOS_System -ComputerName $ComputerName -Credential $Credential).SystemUpTime)
	}
}

############################################# FUNCTION - Services Status 

Function servicestatus ($ServerList, $ServicesList)
{
foreach ($Server in $ServerList) 
	{
  foreach ($Service in $ServicesList)
		{
			$serviceStatus = get-service -ComputerName $Server -Name $Service
			$serverUptime = $Server | Get-UpTime
			
			if ($serviceStatus.status -eq "Running")
			{
				Write-Host $Server `t $serverUptime `t $serviceStatus.name `t $serviceStatus.status -ForegroundColor Green
				$svcName = $serviceStatus.name 
		        $svcState = $serviceStatus.status 
		        Add-Content $report "<tr>"
				Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $Server</B></td>"
				Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $serverUptime</B></td>"
		        Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B>$svcName</B></td>" 
		        Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$svcState</B></td>" 
		        Add-Content $report "</tr>" 
            }
	    	else 
            {
				Write-Host $Server `t $serverUptime `t $serviceStatus.name `t $serviceStatus.status -ForegroundColor Red 
		        $svcName = $serviceStatus.name 
		        $svcState = $serviceStatus.status 
		        Add-Content $report "<tr>"
				Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$Server</td>"
				Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$serverUptime</td>"
		        Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$svcName</td>" 
		        Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>"
		        Add-Content $report "</tr>" 
            }
		}
	}
}

############################################# Call Function 

#### S1 -- (04) -- 
servicestatus $Server1List_DMZ_IIS1 $Services1List_DMZ_IIS1
servicestatus $Server1List_DOMAINSQL2 $Services1List_DOMAINSQL2
servicestatus $Server1List_SRV_GD3_SQL1 $Services1List_SRV_GD3_SQL1
servicestatus $Server1List_SRV_IIS1 $Services1List_SRV_IIS1

#### S2 -- (13) -- DONATION MANAGER 
servicestatus $Server2List_DMZ_S1_IIS1 $Services2List_DMZ_S1_IIS1
servicestatus $Server2List_DMZ_S1_IIS2 $Services2List_DMZ_S1_IIS2
servicestatus $Server2List_DMZ_S1_IIS3 $Services2List_DMZ_S1_IIS3
servicestatus $Server2List_DMZ_S1_IIS4 $Services2List_DMZ_S1_IIS4
servicestatus $Server2List_DMZ_S1_IIS5 $Services2List_DMZ_S1_IIS5
servicestatus $Server2List_DMZ_S1_MAP1 $Services2List_DMZ_S1_MAP1
servicestatus $Server2List_DMZ_S1_MAP2 $Services2List_DMZ_S1_MAP2
servicestatus $Server2List_DMZ_S1_MAP3 $Services2List_DMZ_S1_MAP3
servicestatus $Server2List_DMZ_S1_MAP4 $Services2List_DMZ_S1_MAP4
servicestatus $Server2List_DMZ_S1_MAP5 $Services2List_DMZ_S1_MAP5
servicestatus $Server2List_PD0_ENT_SRS1 $Services2List_PD0_ENT_SRS1
servicestatus $Server2List_PS0_DM_SCH1 $Services2List_PS0_DM_SCH1
servicestatus $Server2List_SRV_GD3_SQL2 $Services2List_SRV_GD3_SQL2

#### S3 -- (06) -- KRONOS 
servicestatus $Server3List_SRV_KROAPP1 $Services3List_SRV_KROAPP1
servicestatus $Server3List_SRV_KROAPP2 $Services3List_SRV_KROAPP2
servicestatus $Server3List_SRV_KROBGP1 $Services3List_SRV_KROBGP1
servicestatus $Server3List_SRV_KRODB1 $Services3List_SRV_KRODB1
servicestatus $Server3List_SRV_KROWDM1 $Services3List_SRV_KROWDM1
servicestatus $Server3List_SRV_KROWWIM1 $Services3List_SRV_KROWWIM1

#### S4 -- (06) -- TRUCKING 
servicestatus $Server4List_DMZ_S2_D2L $Services4List_DMZ_S2_D2L
servicestatus $Server4List_DMZ_S2_IIS1 $Services4List_DMZ_S2_IIS1
servicestatus $Server4List_DMZ_S2_IIS2 $Services4List_DMZ_S2_IIS2
servicestatus $Server4List_DMZ_S2_IIS3 $Services4List_DMZ_S2_IIS3
servicestatus $Server4List_SRV_TS1 $Services4List_SRV_TS1
servicestatus $Server4List_SRV_TS2 $Services4List_SRV_TS2

#### S5 -- (01) -- DYNAMICS 
servicestatus $Server5List_DOMAINSQL1 $Services5List_DOMAINSQL1

#### S6 -- (05) -- ORACLE -- Linux Servers
servicestatus $Server6List_SRVEBSAP1 $Services6List_SRVEBSAP1
servicestatus $Server6List_SRVEBSAP2 $Services6List_SRVEBSAP2
servicestatus $Server6List_SRVEBSAPX $Services6List_SRVEBSAPX
servicestatus $Server6List_SRVEBSDB1 $Services6List_SRVEBSDB1
servicestatus $Server6List_SRV_ORA_NFS1 $Services6List_SRV_ORA_NFS1

#### S7 -- (05) -- FUJITSU
servicestatus $Server7List_PS0_FSC_FND1 $Services7List_PS0_FSC_FND1
servicestatus $Server7List_SRV_FSC_APP3 $Services7List_SRV_FSC_APP3
servicestatus $Server7List_SRV_FSC_APP4 $Services7List_SRV_FSC_APP4
servicestatus $Server7List_SRV_FSC_DB1 $Services7List_SRV_FSC_DB1
servicestatus $Server7List_SRV_RPT_LS1 $Services7List_SRV_RPT_LS1

#### S8 -- (15) -- TEXAS -- Different Network (Unreachable)
servicestatus $Server8List_MNCC_MS5 $Services8List_MNCC_MS5
servicestatus $Server8List_MNCC_MS6_P $Services8List_MNCC_MS6_P
servicestatus $Server8List_MNCC_SM1 $Services8List_MNCC_SM1
servicestatus $Server8List_PS1_DM_CH1 $Services8List_PS1_DM_CH1
servicestatus $Server8List_TXCC_CCS1 $Services8List_TXCC_CCS1
servicestatus $Server8List_TXCC_CIC1 $Services8List_TXCC_CIC1
servicestatus $Server8List_TXCC_CIC2 $Services8List_TXCC_CIC2
servicestatus $Server8List_TXCC_Cluster1 $Services8List_TXCC_Cluster1
servicestatus $Server8List_TXCC_Cluster2 $Services8List_TXCC_Cluster2
servicestatus $Server8List_TXCC_IIS1 $Services8List_TXCC_IIS1
servicestatus $Server8List_TXCC_IIS2 $Services8List_TXCC_IIS2
servicestatus $Server8List_TXCC_MS1 $Services8List_TXCC_MS1
servicestatus $Server8List_TXCC_MS2 $Services8List_TXCC_MS2
servicestatus $Server8List_TXCC_SM1 $Services8List_TXCC_SM1
servicestatus $Server8List_TXCC_SQL4 $Services8List_TXCC_SQL4


############################################# Close HTMl Tables 

Add-content $report  "</table>" 
Add-Content $report "</body>" 
Add-Content $report "</html>" 

############################################# Send Email 

$subject = "ScoreCard Status" 
$body = Get-Content "\\SERVER\SHARE\...\ScoreCard_Report.htm"
$smtp= New-Object System.Net.Mail.SmtpClient $smtphost 
$msg = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body 
$msg.isBodyhtml = $true 
$smtp.send($msg)

############################################# 
 
