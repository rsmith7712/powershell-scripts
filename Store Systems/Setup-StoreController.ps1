# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Setup-StoreController.ps1

.SYNOPSIS
  Script that builds an SLC from a Dell T320. ENGINEERING DOMAIN ONLY
 
.DESCRIPTION
  Formatted Store_Controller_Setup.ps1 to be readable. Script by D. Egerton.
 
.NOTES
  Version:        ENG.1.2
  Author:         user4
  Creation Date:  09/05/2017
  Purpose/Change: Added prompt for DEV/QA, fixed UFO_NUMBER selection, removed some issues.

.HISTORY
  Version:        ENG.1.1 (11/09/2016)
  Purpose/Change: Built from Prod script version 1.1. Ripped out most of the logic to simplify
					process of adding to DOMAIN.ENG
  Version:        1.1
  Purpose/Change: Readability Changes. Added New IP Scheme Info.
  Version:        1.0
  Purpose/Change: Initial ReWrite of Previous Script. Previous Version was 2.39

.FUNCTIONALITY
    Formatted Store_Controller_Setup.ps1 to be readable. Script by D. Egerton.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#---------------------------------------------------------------------------------------------------------------------
# INITIALIZATIONS
$script:script_filepath = $MyInvocation.MyCommand.Path
$script:script_dir = Split-Path -Parent $script:script_filepath
$script:script_name = $MyInvocation.MyCommand.Name	
$ErrorActionPreference = "SilentlyContinue"
# ----------------------------------------------------------------------------------------------------------------------------
# GLOBALS
Add-Type -AssemblyName System.Windows.Forms 
Clear-Host
$script:local_ip  = ((Test-Connection $env:computername -Count 1).ipv4address).ipaddresstostring		
$script:ip_parsed = $local_ip.split(".")
$ip_octet_2 = $ip_parsed[1]
$script:ipscheme = 2
				
#$store_center_server 				= "TEST-FSC-APP1"	 #Changed to prompt user for selection down below.
$script:continue_flag 				= $TRUE		
$terminal_number					= 90				# STORE CONTROLLER ALWAYS = 90
$sql_user_id 						= "DomainSA"
$sql_password 						= '<password>'   				
#---------------------------------------------------------------------------------------------------------------------
# LOG FUNCTIONS	
function logstamp(){
	$now=get-Date
	$yr=$now.Year.ToString()
	$mo=$now.Month.ToString()
	$dy=$now.Day.ToString()
	$hr=$now.Hour.ToString()
	$mi=$now.Minute.ToString()
	$ss = $now.Second.ToString()
	if ($mo.length -lt 2) {
		$mo="0$mo"
	    }
	if ($dy.length -lt 2) {
		$dy="0$dy"
	    }
	if ($hr.length -lt 2) {
		$hr="0$hr"
	    }
	if ($mi.length -lt 2) {
		$mi="0$mi"
	    }
	if ($ss.length -lt 2) {
		$ss="0$ss"
	    }
	$thelogstamp = $yr+$mo+$dy+"_"+$hr+$mi+$ss
	return $thelogstamp
	}
function log_environment_info(){                    	
	$thedate = Get-Date
	$logheader = "Log Created: " + $thedate
	$section   = "-------------------------------------------------------------------------"
	$ipaddress = ((Test-Connection $env:computername -Count 1).ipv4address).ipaddresstostring
	$machineinfo = gc env:computername							
	$user_name =  gc env:username
											
	Add-Content $script:log_full_filepath "`n$logheader"
	Add-Content $script:log_full_filepath "`n$section"
	Add-Content $script:log_full_filepath "`nIP Address: $ipaddress"
	Add-Content $script:log_full_filepath "`nMachine Name: $machineinfo"
	Add-Content $script:log_full_filepath "`nUser Name: $user_name"
	Add-Content $script:log_full_filepath "`n$section"                                  
	}
function append_log($message){	
	Add-Content $script:log_full_filepath "`n$message"
	}
function read_log(){					
	$log_content = gc $script:log_full_filepath                         
	return $log_content
	}	
function create_new_log_file(){
	# Set path for Logging
	$logstamp = logstamp
	$filename = "SCConfiguration_log_" + $logstamp + ".txt"
	$outFilePath = "$script:log_dir$filename"						
	New-Item $outFilePath -type file
	$script:log_full_filepath = $outFilePath   
	set_reg_LogPath $outFilePath
	log_environment_info   
	}
# -----------------------------------------------------------------------------------------------------------------           
# FUNCTIONS
function idrac_config{
    $ping = new-object system.net.networkinformation.ping
    $dracip = 9
    $subnetmask = "255.0.0.0"
    $ip_3_octets = $script:ip_parsed[0]+'.'+$script:ip_parsed[1]+'.'+$script:ip_parsed[2]
    $IP = $ip_3_octets+'.'+$dracip
    $Gateway = $ip_3_octets+'.'+'1'
    $TestIP = $ping.send($IP)
    If($TestIP.Status -ne "Success"){
        & racadm setniccfg -s $IP $subnetmask $gateway
        }
    }
 
function pause_script{
	param
	(
		$previous,
		$next
	)	
	write-host "--------------------------------------------------------------------------"
	write-host "    Previous Step: $previous"
	write-host "    Next Step: $next"
	$wait = read-host "    Press any key to continue"				
	write-host "--------------------------------------------------------------------------"
	}
function check_for_keys(){
	$key_result = Test-Path "HKLM:\SOFTWARE\DomainControllerConfiguration" -erroraction silentlycontinue
	return $key_result                      
	}   
function create_keys(){
	#reg folder - Created as part of the Environment Check
	#New-Item -Path HKLM:\SOFTWARE -Name DomainControllerConfiguration             							
	# reg key CurrentStep ... integer
	New-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name CurrentStep -PropertyType DWord -Value 0 
	# reg key ResumeStep ... integer
	New-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name ResumeStep -PropertyType DWord -Value 0
	# reg key log_path  
	New-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name log_path -PropertyType String -Value 0          
	# reg key success
	New-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name success -PropertyType DWord -value 0    						
	}      
function remove_keys(){
	Remove-Item -Path HKLM:\SOFTWARE\DomainLaneConfiguration
	}
function get_reg_ResumeStep(){
	$resume_step = (Get-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name ResumeStep).ResumeStep
	return $resume_step
	}   
function set_reg_ResumeStep($new_resume_step){    								
	Set-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name ResumeStep -Value $new_resume_step			
	} 	
function get_reg_CurrentStep(){
	$key_value = (Get-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name CurrentStep).CurrentStep
	return $key_value
	}   
function set_reg_CurrentStep($current_step){    								
	Set-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name CurrentStep -Value $current_step			
	} 	
function get_reg_success(){
	$key_value = (Get-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name success).CurrentStep
	return $key_value
	}   
function set_reg_success($value){    								
	Set-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name success -Value $value			
	} 	
function get_reg_LogPath(){
	$log_path = (Get-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name LogPath).LogPath
	return $log_path
	}   
function set_reg_LogPath($new_log_path){    								
	Set-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name LogPath -Value $new_log_path
	}
function get_file_version($target_path){
	# test target_path 
	$testpath_result = Test-Path $target_path				
	if ($testpath_result){ # if found, get file version 
		$intermediate = get-content $target_path | select-string -list -pattern 'fileversion:'            
		$contents = $intermediate[0]        
		ForEach ($line in $contents){
			$version = $line -Split ':'        
			$fileversion = $version[1]
			}
		}
	else{ # else return not found
		$fileversion = -1
		}
	return $fileversion
	}
function get_highest_free_driveletter{ # http://stackoverflow.com/questions/12488030/getting-a-free-drive-letter
	$AllLetters = 65..90 | ForEach-Object {[char]$_ + ":"}
	$UsedLetters = get-wmiobject win32_logicaldisk | select -expand deviceid
	$FreeLetters = $AllLetters | Where-Object {$UsedLetters -notcontains $_}
	$highest_free_letter = $FreeLetters | select-object -last 1				
	return $highest_free_letter
	}
function stop_services(){	
	function FuncCheckService{
		param($ServiceName)
		$arrService = Get-Service -Name $ServiceName
		return $arrService.Status					
	    }			
	function FuncStopService{
		param($ServiceName)
		Get-Service -Name $ServiceName | stop-service -Force -ErrorAction SilentlyContinue									
	    }	
	Add-Content $script:log_full_filepath "--------------------------------------------------"
	Add-Content $script:log_full_filepath "STOPPING SERVICES"	
	$services = @(
	    'Raft Event Monitor',
	    'HMS Service Host',
	    'SCConnectivity',
	    'GlobalSTORE Populate',
	    'RAFT Electronic Journal Transfer Service',
	    'PSI RPC Server',				
	    'SQLSERVERAGENT',
	    'HMS Router'
	    )	
	foreach ($service in $services){
		Add-Content $script:log_full_filepath " -- Stopping $service"
		FuncStopService $service				
		Add-Content $script:log_full_filepath " -- Checking $service"
		$result = FuncCheckService $service
		Add-Content $script:log_full_filepath  " ------ $service is $result"
	    }		
	Add-Content $script:log_full_filepath "STOPPING SERVICES"
	Add-Content $script:log_full_filepath "--------------------------------------------------"
	}
function update_image_def_xml(){

	Add-Content $script:log_full_filepath "UPDATE IMAGE DEF XML"
	# prepare
	$sql_user_id = $script:sql_user_id
	$sql_password = $script:sql_password

	# define file path
	$image_update_def_filepath = 'C:\gstr\ApplicationTools\bin\ImageUpdateDefs.xml'      

	# test for file's existence
	$filetest = Test-Path $image_update_def_filepath
	Add-Content $script:log_full_filepath "$image_update_def_filepath found =  $filetest"
			
	# if file exists
	if ($filetest){
		# load the image update utility xml
		$image_update_definition_file = New-Object XML
		$image_update_definition_file.psbase.PreserveWhitespace = $true     
		$image_update_definition_file.Load($image_update_def_filepath) 
		# if sql_user_id property exists, fill in value, else create new node
		if ( !($image_update_definition_file.ImageUpdateDefs.Properties.Property | Where-Object {$_.name -eq "sqluserid"}) ){ # property does not exist, create property
			$sql_user_id_property_body = '<Property name="sqluserid" value="' + "$sql_user_id" + '"/>'
			$sql_user_id_property = [xml] "$sql_user_id_property_body"      
			$newNode = $image_update_definition_file.ImportNode($sql_user_id_property.Property, $true)
			$image_update_definition_file.ImageUpdateDefs.Properties.AppendChild($newNode)
		    }
		else{ # property does exist, insert user id
			$IUD_sqluserid = $image_update_definition_file.ImageUpdateDefs.Properties.Property | Where-Object {$_.name -eq "sqluserid"}
			$IUD_sqluserid.value = $sql_user_id
		    }
		# if sql_password property exists, fill in value, else create new node
		if ( !($image_update_definition_file.ImageUpdateDefs.Properties.Property | Where-Object {$_.name -eq "sqlpassword"}) ){ # property does not exist, create new property
			$sql_password_property_body = '<Property name="sqlpassword" value="' + "$sqlpassword" + '"/>'
			$sql_password_property = [xml] "$sql_password_property_body"        
			$newNode = $image_update_definition_file.ImportNode($sql_password_property_body.Property, $true)
			$image_update_definition_file.ImageUpdateDefs.Properties.AppendChild($newNode)
		    }
		else{ # property does exist, insert password value
			$IUD_sqlpassword = $image_update_definition_file.ImageUpdateDefs.Properties.Property | Where-Object {$_.name -eq "sqlpassword"}
			$IUD_sqlpassword.value = $sql_password
		    }       
		# save back to xml file
		$image_update_definition_file.Save($image_update_def_filepath)                  
		$image_update_definition_file.ImageUpdateDefs.Properties.Property		
		$script:continue_flag = $true
	    }
	else{  #file is not found
		Add-Content $script:log_full_filepath " -----------------------------------------------------------------------------"
		Add-Content $script:log_full_filepath "Test for existence of $image_update_def_filepath is $filetest"			
		Add-Content $script:log_full_filepath "Unable to continue"
		Add-Content $script:log_full_filepath " -----------------------------------------------------------------------------"				
		$script:continue_flag = $false
		}
	Add-Content $script:log_full_filepath "UPDATE IMAGE DEF XML"
	Add-Content $script:log_full_filepath "--------------------------------------------------"
    }  
function run_IUU(){
	param
	(
		$store_controller,
		$UFO_NUMBER,
		$db_server,
		$app_server,
		$store_center_server,
		$sql_user,
		$sql_password,
		$terminal_number
	)	
	Add-Content $script:log_full_filepath "--------------------------------------------------"
	Add-Content $script:log_full_filepath "RUN IUU"

    $subnet = "255.0.0.0"
    $location = 'c:\gstr\ApplicationTools\bin\ImageUpdateUtility'           

	# set command line parameters
	$switch1 			= "-updatedefs:C:\gstr\ApplicationTools\bin\ImageUpdateDefs.xml"           
	$switch2 			= "-silent"            
	$machinename_switch	= "-D:newmachinename=$store_controller"        								
	$UFO_NUMBER_switch = "-D:UFO_NUMBER=$UFO_NUMBER"        
	$dbserver_switch 	= "-D:dbservername=$db_server"
	$appserver_switch 	= "-D:appservername=$app_server"
	$storecenter_switch = "-D:scserver=$store_center_server"
	$sqluser_switch		= "-D:sqluserid=$sql_user"
	$sqlpassword_switch	= "-D:sqlpassword=$sql_password"
	$terminal_switch	= "-D:terminalnumber=$terminal_number"

	# combine arguments
	$allArgs = @($switch1,$switch2,$UFO_NUMBER_switch,$dbserver_switch,$appserver_switch,$storecenter_switch,$terminal_switch,$machinename_switch)     
	# attended operation prompt
	$test_run_command_line =  "C:\gstr\ApplicationTools\bin\ImageUpdateUtility.exe $allArgs"            
					
	write-host $test_run_command_line
	#--------------------------------------------      							
	$OFS = "`n"
	$iuu_output = & "C:\gstr\ApplicationTools\bin\ImageUpdateUtility.exe" $allArgs 			

	foreach ($output_line in $iuu_output){
		Add-Content $script:log_full_filepath "IUU Output --> $output_line"
	    }					
	Add-Content $script:log_full_filepath "RUN IUU"
	Add-Content $script:log_full_filepath "--------------------------------------------------"
    }						
function join_domain(){				
	$message  = "pausing 60 sec before attempting to join domain"
	Add-Content $script:log_full_filepath $message
	write-host $message
				
	start-sleep -s 60				

	$message  = "resume"
	Add-Content $script:log_full_filepath $message
	write-host $message
				
	# join this computer to DOMAIN domain
	$domainuser = 'example.com\SLCADMIN'
	$domainpass = ConvertTo-SecureString "<password>" -AsPlainText -Force
	$DomainCred = New-Object System.Management.Automation.PSCredential $domainuser, $domainpass
	$commandresult = Add-Computer -DomainName DOMAIN.ENG -credential $DomainCred		
	Add-Content $script:log_full_filepath $commandresult
    }	
function prepare_crypto_config(){
	param
	(
		$store_controller,
		$UFO_NUMBER
	)	   		
	$cryptofile = "C:\gstr\Crypto\bin\CryptoSecurity.config.xml"
	$crypto = New-Object System.Xml.XmlDocument
	$crypto.psbase.PreserveWhitespace = $TRUE

	$crypto.Load($cryptofile)
	$cryptobase = $crypto.CryptoSecuritySetting.xmlSerializerSection.GSCryptographyData 
	$server = $cryptobase.ServerName							
	$cryptobase.ServerName = "$store_controller"          							
	$connectionstring = "Driver={SQL Server};Server=(local);Database=CryptoCache;Trusted_Connection=yes"							
	$cryptobase.ConnectString = "$connectionstring"       
	$mgr = "DOMAIN.ENG\" + $UFO_NUMBER + "MGR"
	$csh = "DOMAIN.ENG\" + $UFO_NUMBER + "CSH"
	$str = "DOMAIN.ENG\" + $UFO_NUMBER + "STR"					
	$users = $cryptobase.groupserver.user
	if (!($users -contains 'example.com\SLCADMIN')){ 
		$newNode = $crypto.CreateElement("user")
		$newNode.InnerText = "example.com\SLCADMIN"
		$crypto.CryptoSecuritySetting.xmlSerializerSection.GSCryptographyData.groupserver.AppendChild($newNode) 
	    }
	if (!($users -contains 'example.com\ORGADMINS')){ 
		$newNode = $crypto.CreateElement("user")
		$newNode.InnerText = "example.com\ORGADMINS"
		$crypto.CryptoSecuritySetting.xmlSerializerSection.GSCryptographyData.groupserver.AppendChild($newNode) 
	    }
	if (!($users -contains 'FUJITSU')){ 
		$newNode = $crypto.CreateElement("user")
		$newNode.InnerText = "FUJITSU"
		$crypto.CryptoSecuritySetting.xmlSerializerSection.GSCryptographyData.groupserver.AppendChild($newNode) 
	    }
	if (!($users -contains 'SETUP')){ 
		$newNode = $crypto.CreateElement("user")
		$newNode.InnerText = "SETUP"
		$crypto.CryptoSecuritySetting.xmlSerializerSection.GSCryptographyData.groupserver.AppendChild($newNode) 
	    }
	if (!($users -contains 'example.com\HELPDSK')){ 
		$newNode = $crypto.CreateElement("user")
		$newNode.InnerText = "example.com\HELPDSK"
		$crypto.CryptoSecuritySetting.xmlSerializerSection.GSCryptographyData.groupserver.AppendChild($newNode) 
	    }
	if (!($users -contains $mgr)){ 
		$newNode = $crypto.CreateElement("user")
		$newNode.InnerText = "$mgr"
		$crypto.CryptoSecuritySetting.xmlSerializerSection.GSCryptographyData.groupserver.AppendChild($newNode) 
	    }
	if (!($users -contains $csh)){ 
		$newNode = $crypto.CreateElement("user")
		$newNode.InnerText = "$csh"
		$crypto.CryptoSecuritySetting.xmlSerializerSection.GSCryptographyData.groupserver.AppendChild($newNode) 
	    }
	if (!($users -contains $str)){ 
		$newNode = $crypto.CreateElement("user")
		$newNode.InnerText = "$str"
		$crypto.CryptoSecuritySetting.xmlSerializerSection.GSCryptographyData.groupserver.AppendChild($newNode) 
	    }
	$crypto.save("$cryptofile")
    }		
    			
function run_crypto(){
	# pause 60 seconds - to allow database connections to come online
	$message  = "pausing 60 sec before attempting to run crypto"
	Add-Content $script:log_full_filepath $message			
	start-sleep -s 120				
	$message  = "resume"
	Add-Content $script:log_full_filepath $message			
	# execute crypto				
	$commandline = 'C:\gstr\Crypto\bin\CryptoDomain.cmd'
	$output = & "$commandline"
	foreach ($output_line in $output){						
		$message =  $output_line
		write-host $message
		Add-Content $script:log_full_filepath $message						
		}		
    }			
function test_crypto_registry(){
	$crypto_sessionkey = (Get-ItemProperty -Path HKLM:\SOFTWARE\Wow6432Node\GlobalStore\Cryptography -Name SessionKey).SessionKey
	write-host "Crypto Results "+$crypto_sessionkey[0]+" "+$crypto_sessionkey[1]
    }			
function add_CSH_account_to_cryptographers($UFO_NUMBER){				
	# prepare
	$computer_name =  gc env:computername            				
	$adsi_line = "WinNT://$computer_name/GSCryptographers,group"
	$adsi_add_line = "WinNT://"+$script:UFO_NUMBER+"CSH,user"            
	# Add %%%%CSH to GSCryptographers
	$group = [ADSI]"$adsi_line"
	$group.add("$adsi_add_line") 
    }
function ip_configuration(){  			
	$ip_parsed = $script:ip_parsed
	$ip_3_octets = $ip_parsed[0] + "." + $ip_parsed[1]	+ "." + $ip_parsed[2]	
							
	# build static ip               
	$ip_octet_4 = 10
	$new_ip = "$ip_3_octets"+"."+$ip_octet_4														
	# common ip settings
	$gateway 		= $ip_3_octets +'.'+'1'
    $subnet 		= "255.0.0.0"
	$DNS 			= "0.0.0.0","0.0.0.0" 
	$wins1 			= "0.0.0.0"
	$wins2 			= "0.0.0.0"

	# IN PRODUCTION, THE SERVER WILL ALWAYS HAVE A BASP BROADCOM NIC TO SET TO STATIC.			
	# get all adapters		
	$all_adapters = get-wmiobject -class win32_networkadapter				
	# only get connected adapters					
	$connected_adapters = $all_adapters | where-object {$_.netconnectionstatus -eq 2}
					
	# IF a BASP adapter is found & connected, use that
	if ($connected_adapters | where-object {$_.name -eq "BASP Virtual Adapter"}){
		$adapter = Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'Description = "BASP Virtual Adapter"'
	    }				
	else { # else use the default connected adapter 
		$adapter = Get-WmiObject -class win32_NetworkAdapterConfiguration | where-object {$_.DHCPEnabled -eq "True" -and $_.IPAddress -ne $null}						
	    }				
	# set selected adapter to static ip					
	$adapter.EnableStatic($new_ip, $subnet)
	$adapter.SetGateways($gateway, [UInt16] 1) 
	$adapter.SetDNSServerSearchOrder($DNS)
	$adapter.SetWINSServer($wins1,$wins2)    					
    }
			
function install_frame_package(){						
	$commandline = "C:\Software\SLC_Setup\InstallFramePkg.bat"		
	$frame_package_path = "c:\software\framepkg.exe"
	$frame_package_test = Test-Path -Path $frame_package_path				
	if ($frame_package_test){
		$message =  $commandline
		write-host $message
		Add-Content $script:log_full_filepath $message			
		$output = &"$commandline"
		foreach ($line in $output){	
			$message =  $line
			write-host $message
			Add-Content $script:log_full_filepath $message
		    }					
	    }						
    }		
function test_domain{
	function test_domain_membership{
		start-sleep -s 30			
		if ((gwmi win32_computersystem).partofdomain -eq $true) {
			write-host -fore green "I am domain joined!"
			$message =  "Part of domain"
			write-host $message
			Add-Content $script:log_full_filepath $message
			return $true			
		    } 
		else {
			$message =  "Part of workgroup"
			write-host -fore red "Ooops, workgroup!"
			write-host $message
			Add-Content $script:log_full_filepath $message
			return $false
		    }
	    }			
	$result = test_domain_membership
	if (!$result){				
		$wait = read-host "Machine did not join domain. Please manually join. Then come back here and press any key to continue"			
		$message =  "Prompted user to join domain"												
		Add-Content $script:log_full_filepath $message					
	    }
    }			
			
function last_step{
	$message =  "--------------------------------------------------"
	write-host $message
	Add-Content $script:log_full_filepath $message			
	$message =  "Final Step"
	write-host $message
	Add-Content $script:log_full_filepath $message			
	set_reg_success 1			
	$message =  "--------------------------------------------------"
	write-host $message
	Add-Content $script:log_full_filepath $message				
	restart-computer -force
    }

function setup_login(){           
	$Enable = "1"
	$Username = "Setup"
	$DefaultPassword = '<password>'
	$WinlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"       
	if ((Get-ItemProperty $WinlogonPath).AutoLogonCount -ne $null){
		Remove-ItemProperty -Path $WinlogonPath -Name AutoLogonCount -ErrorAction SilentlyContinue
	    }       
	# Store the autologon registry settings.
	Set-ItemProperty -Path $WinlogonPath -Name AutoAdminLogon -Value $Enable -Force
	Set-ItemProperty -Path $WinlogonPath -Name DefaultUserName -Value $Username -Force
	Set-ItemProperty -Path $WinlogonPath -Name DefaultPassword -Value $DefaultPassword -Force           
	Set-ItemProperty -Path $WinlogonPath -Name ForceAutoLogon -Value $Enable -Force               						
    }   
function rebootresume($step){                                                                      
	# assumes that a resume point has been set in HKLM\SOFTWARE\DomainConfig....   
	# enable a reboot resume by adding a HKLM RUN key for the current script							
	$next_step = $step + 1							
	set_reg_LogPath( $script:log_full_filepath )
	set_reg_ResumeStep($next_step)							
	# build reg key 
	$pspath = 'c:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe'       
	$regcommand = "$pspath -noexit $script:script_filepath"                                 
	Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -name "imageconfig" -value "$regcommand"                                                   
	# restart       
	restart-computer -force
	exit
    }
function clear_rebootresume(){   
	# build reg key 								
	$regcommand = ""                                 
	Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -name "imageconfig" -value "$regcommand"                                                   							
    }
function clear_login(){   
	$Disable = "0"
	$Username = ''
	$DefaultPassword = ''
	$WinlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"       
	if ((Get-ItemProperty $WinlogonPath).AutoLogonCount -ne $null){
		Remove-ItemProperty -Path $WinlogonPath -Name AutoLogonCount -ErrorAction SilentlyContinue
	    }       
	# Store the autologon registry settings.
	Set-ItemProperty -Path $WinlogonPath -Name AutoAdminLogon -Value $Enable -Force
	Set-ItemProperty -Path $WinlogonPath -Name DefaultUserName -Value $Username -Force
	Set-ItemProperty -Path $WinlogonPath -Name DefaultPassword -Value $DefaultPassword -Force           
	Set-ItemProperty -Path $WinlogonPath -Name ForceAutoLogon -Value $Disable -Force                                         								
	}
	
function Get-Environment{
	$Path = "HKLM:\SOFTWARE\DomainControllerConfiguration"
	$EnvironmentCheck = (Get-ItemProperty -Path HKLM:\Software\DomainControllerConfiguration -EA SilentlyContinue).Environment
	If(!(Test-Path $Path))
	{
		New-Item -Path HKLM:\SOFTWARE -Name DomainControllerConfiguration
		New-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name Environment -PropertyType DWord -Value 0 
	}
	If($EnvironmentCheck -eq 0)
	{	
		$title = "Choose an Environment"
		$message = "Which Environment is this SLC in?"
		$DEV = New-Object System.Management.Automation.Host.ChoiceDescription "&DEV", `
			"Will use the DS0 StoreCenter and LM/RM Environments."
		$QA = New-Object System.Management.Automation.Host.ChoiceDescription "&QA", `
			"Will use the QS0 StoreCenter and LM/RM Environments."
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($DEV, $QA)
		$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
		switch ($result)
		{
			0 {
				Set-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name Environment -Value "DEV"
				Return "DS0-FSC-APP1.Domain.eng"
			}
			1 {
				Set-ItemProperty -Path HKLM:\SOFTWARE\DomainControllerConfiguration -Name Environment -Value "QA"
				Return "QS0-FSC-APP1.Domain.eng"
			}
		}
	}
	Else
	{
		switch($EnvironmentCheck)
		{
			"DEV"{
				Return "DS0-FSC-APP1.Domain.eng"
			}
			"QA"{
				Return "QS0-FSC-APP1.Domain.eng"
			}
		}
	}
}
function return_store($ip_address){
	$ip_parsed = $script:ip_parsed
	$labranges = @("19","29","39")					
	if ($labranges -contains $ip_parsed[1]) #Engineering Domain Lab Store
	{
		$lab_store = $ip_parsed[1]+$ip_parsed[2]
		return $lab_store
	}
	Else
	{
		Write-Host "Unable to find Engineering UFO_NUMBER"
		Exit
	}
}
# -------------------------------------------------------------------------------------------------------------------			
# Script
# UFO_NUMBER Resolution
$UFO_NUMBER = return_store $local_ip
$store_center_server = Get-Environment
$db_server 					= "$UFO_NUMBER"+"SLC1"
$app_server  				= "$UFO_NUMBER"+"SLC1"
$store_controller			= "$UFO_NUMBER"+"SLC1"
if (check_for_keys){# KEYS FOUND							
	if (get_reg_success -eq  1){	
		write-host "Keys Found. Success = True.  Reconfigure this machine?"
		$response = read-host "type yes or no"
		if ($response -eq 'yes'){
			$script:continue_flag = $true
		    }
		else{
			$script:continue_flag = $false					
		    }		
		If ($script:continue_flag) { 
			$newrun = $TRUE		
		    } 
		else{
			exit
		    }
	    }
	else{ # NOT SUCCESSFUL, IS RESUME? 
		write-host "Keys Found. Success = False."
	    if (get_reg_ResumeStep -gt 0){						
		    # IS RESUMED SCRIPT, START AT RESUME POINT	
		    $newrun = $FALSE
		    $script:log_full_filepath 	= get_reg_LogPath							
		    $i							= get_reg_ResumeStep
		    $message = "Is script in progress"
		    write-host $message
		    Add-Content $script:log_full_filepath $message			
		    set_reg_ResumeStep 0			
		    $message =  "Resuming Script at position $i	"
		    write-host $message
		    Add-Content $script:log_full_filepath $message		
		    $script:continue_flag = $TRUE
	    }
	    else{	
		    write-host "No resume step was set - starting over"						
		    $newrun = $TRUE									
		    $script:continue_flag = $TRUE
	        }
	    }
    }
else{ # NO KEYS FOUND, START NEW
	$newrun = $TRUE
	create_keys						
	$script:continue_flag = $TRUE								
    }

if ($newrun){
	#$store_center_server = Get-Environment
    idrac_config				
	set_reg_ResumeStep 0
	set_reg_success 0
	$i = 0			
	# log file path variables
	$script:script_filepath 			= $MyInvocation.MyCommand.Path
	$script_dir 						= Split-Path -Parent $script:script_filepath
	# test for existence of log directory
	$script:log_dir 					= "$script_dir\Logs\" 
	$test_log_dir 						= Test-Path -Path $script:log_dir
	# if does not exist, create directory
	if(!($test_log_dir)){
		new-item -Name "Logs" -ItemType Directory -Path $script_dir
	    }
	create_new_log_file							
	$message = "Fileversion: " + "$my_version"
	Add-Content $script:log_full_filepath $message					
    }
# ARRAY OF STEPS							
$step_list =  
@(	
	'stop_services ',
	'update_image_def_xml',
	'run_IUU $store_controller $UFO_NUMBER $db_server $app_server $store_center_server $sql_user $sql_password $terminal_number',
	'setup_login',
	'rebootresume $i',
	'clear_rebootresume',
	'clear_login',
	'join_domain',
	'setup_login',
	'rebootresume $i',				
	'clear_rebootresume',
	'clear_login',
	'test_domain',
	'prepare_crypto_config $store_controller $UFO_NUMBER',				
	'run_crypto',
	'ip_configuration',
	'install_frame_package',      								
	'setup_login',
	'rebootresume $i',
	'clear_rebootresume',
	'clear_login',
	'last_step'											
)
$listlength = $step_list.length					
					
while (($i -lt $step_list.length) -and ($script:continue_flag)){                            
	set_reg_CurrentStep $i												
	$commandname = $step_list[$i] 
	Add-Content $script:log_full_filepath "--------------------------------------------------"
	Add-Content $script:log_full_filepath "--------------------------------------------------"						
	$message = "Step " + "$i" + " of " + "$listlength"	+ " " + "$commandname"
	Add-Content $script:log_full_filepath $message						
	Add-Content $script:log_full_filepath "------------------------------------"						
	Invoke-Expression $step_list[$i]               
	Add-Content $script:log_full_filepath "--------------------------------------------------"
	Add-Content $script:log_full_filepath "--------------------------------------------------"								
	$i = $i + 1;
    }
$wait = read-host "press any key"