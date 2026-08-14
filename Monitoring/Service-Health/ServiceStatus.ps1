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
    ServiceStatus.ps1.txt

.DESCRIPTION
    Checks the status of defined services across several server lists (management, Exchange, SQL).

.FUNCTIONALITY
    Checks service status across server lists.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

############################Define Server & Services Variable ###############
$Server1List = Get-Content ".\Servers.txt"
$Services1List = Get-Content ".\Servers1.txt"

$Server2List = Get-Content ".\LDMSServer.txt"
$Services2List = Get-Content ".\LDMSServer1.txt"

$Server3List =  Get-Content ".\ExchServer.txt"
$Services3List = Get-Content ".\ExchServer1.txt"

$Server3List =  Get-Content ".\SQLServer.txt"
$Services3List = Get-Content ".\SQLServer1.txt"

#############################Define other variables##########################


$report = ".\SSG1_Services_Report.htm" 

$smtphost = "smtpi.example.com" 
$from = "ServiceStatus@example.com" 
$to = "user1@example.com"

##############################################################################

$checkrep = Test-Path ".\SSG1_Services_Report.htm" 

If ($checkrep -like "True")

{

Remove-Item ".\SSG1_Services_Report.htm"


}

New-Item ".\SSG1_Services_Report.htm" -type file

################################ADD HTML Content#############################


Add-Content $report "<html>" 
Add-Content $report "<head>" 
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $report '<title>Service Status Report</title>' 
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
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>Service Status Report</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
 
add-content $report  "<table width='100%'>" 
Add-Content $report "<tr bgcolor='IndianRed'>" 
Add-Content $report  "<td width='10%' align='center'><B>Server Name</B></td>" 
Add-Content $report "<td width='50%' align='center'><B>Service Name</B></td>" 
Add-Content $report  "<td width='10%' align='center'><B>Status</B></td>" 
Add-Content $report "</tr>" 


########################################################################################################

################################## Get Services Status #################################################

Function servicestatus ($serverlist, $serviceslist)

{

foreach ($machineName in $serverlist) 

 { 
  foreach ($service in $serviceslist)
     {
  
      $serviceStatus = get-service -ComputerName $machineName -Name $service
    
		 if ($serviceStatus.status -eq "Running") {
 
         Write-Host $machineName `t $serviceStatus.name `t $serviceStatus.status -ForegroundColor Green 
         $svcName = $serviceStatus.name 
         $svcState = $serviceStatus.status         
         Add-Content $report "<tr>" 
         Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $machineName</B></td>" 
         Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B>$svcName</B></td>" 
         Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$svcState</B></td>" 
         Add-Content $report "</tr>" 
              
                                                   }

	        else 
                                                   { 
       Write-Host $machineName `t $serviceStatus.name `t $serviceStatus.status -ForegroundColor Red 
         $svcName = $serviceStatus.name 
         $svcState = $serviceStatus.status          
         Add-Content $report "<tr>" 
         Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$machineName</td>" 
         Add-Content $report "<td bgcolor= 'GainsBoro' align=center>$svcName</td>" 
         Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>" 
         Add-Content $report "</tr>" 
         
                                                  } 

             

       } 


 } 

}

############################################Call Function#############################################

servicestatus $Server1List $Services1List
servicestatus $Server2List $Services2List
servicestatus $Server3List $Services3List
servicestatus $Server4List $Services4List

############################################Close HTMl Tables#########################################


Add-content $report  "</table>" 
Add-Content $report "</body>" 
Add-Content $report "</html>" 



#####################################################################################################
#############################################Send Email##############################################


$subject = "Server Group 1 Service Monitor" 
$body = Get-Content ".\SSG1_Services_Report.htm" 
$smtp= New-Object System.Net.Mail.SmtpClient $smtphost 
$msg = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body 
$msg.isBodyhtml = $true 
$smtp.send($msg) 

#####################################################################################################
 
