<#
    ENLIGHTENMENT
        Fabrication Creator: Zachary Lundgren
        Fabrication Date: 12/11/2017
        Corporate Guild: Domain, Inc.
        Filename: Landesk Check and Installaion
    
    STATE PURPOSE
        To check if LANDesk Agent is installed and updated to the latest version on all store ticketing computers.
    
    VARIANT INFO
        [RECORD ANY CHANGES MADE HERE]
#>

# [IMPORTS---------------------------------------------------------------------------------------]
Import-Module ActiveDirectory

# [LOGGING---------------------------------------------------------------------------------------]
$stamp = get-date -Format s | foreach {$_ -replace ":", "."} #Variable holds the time stamp for the filename.
$Script:Logfile = 'C:\The Proving Grounds\PowerShell\VSCode\Domain\STC_LDATest_$stamp.txt' #Create variable for logfile document/txt location. If using this on a different machine, please configure location or # it out.
New-Item -Path $Script:Logfile -ItemType File -Force #Creates a new path (document/txt) to logfile location.
Add-Content $Script:Logfile "Zachary Lundgren, STC = Store Ticketing Computer, LDA =  LandDesk Agent."
function Append-Log($message) { #Creates additional messages into the logfile whenever the function is called.
    $thetime = Get-Date -Format f #Optional input customize the format of the time and input the variable however desired.
	Add-Content $Script:LogFile "[$thetime]: $message" #Like this<<
}

# [FUNCTIONS-------------------------------------------------------------------------------------]
function GetAllStoreComputers($outputFile) { #Gather a list of store computers from the AD and export into a text file. Need the information to put into an Excel doc. for a project. Just # when in use by another character.
    Get-ADComputer -Filter * -Property * | Select-Object Name | Out-File "$outputFile\STResult.txt"
}

function GetLDAgent($outFile) { #Pull installed programs that are similar to the name "LANDESK". Just # when in use by another character.
    #Reads through the registry and attains the registry keys from the Active Directory. 
    Get-ADComputer -Filter * -Property * | Select-Object example.com | Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
    Select-Object DisplayName,DisplayVersion,Publisher,InstallDate | Format-Table -Wrap -AutoSize | Out-File "$outFile\AgentResult.txt"
}

function Install_LanDeskAgent($computer) { #When called, it copies files needed, then installs LDAgent remotely on the store computer itself.
    $agentPath = '\\$stComputer\c$\...\LDAgent'
    $ldPath = '\\$stComputer\c$\...\LANDesk'
    $dbAppPath = '\\SERVER\SHARE\LDMSAgentORGRegTagEPS.exe'
    $ldAppPath = '\\$stComputer\c$\...\LDMSAgentORGRegTagEPS.exe'

    if(!(Test-Path $ldPath)) { #Tests the path of the Landesk folder; if it ceases to exist, it shall create a new folder then copy the files from the Domain share file to the store computer.
        New-Item -Path $ldPath -ItemType Directory -Force
    }

    if(!(Test-Path $agentPath)) { #Tests the path of the folder if ceases to exist, it shall create a new folder then copy the files from the Domain share file to the store computer.
        New-Item -Path $agentPath -ItemType Directory -Force
        #Copy-Item $dbAppPath -Destination $ldPath -Force

        #New-PSDrive -Name X -PSProvider FileSystem -Root \\MyRemoteServer\c$\...\
        #cd X:\
        #cp ~\Desktop\MyFile.txt .\
        ## Important, need to exit out of X:\ for unmouting share
        #cd c:\
        #Remove-PSDrive X

        #$Session = New-PSSession -ComputerName $computer
        #Copy-Item $dbAppPath -Destination $ldPath -Recurse -Credential example.com\opsadmin -ToSession $Session
    }

    Invoke-Command -ComputerName $computer -ScriptBlock{ #Remotes into the computer and runs the executable for LANDesk Agent.
        Copy-Item $dbAppPath -Destination $ldPath -Force
        Start-Process -FilePath $ldAppPath -Wait
        Get-Service -Name LDSecSvc | Start-Service
    }

    Invoke-Command -ComputerName $computer -ScriptBlock{ #Validate that the application is installed.
        if([IntPtr]::Size -eq 4) { #Checks the system; IntPtr is pretty much "system", so it looks for 32 bit programs, hence the '4'; 8 being 64 bit.
            $regPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        }else { #If it isn't 32 bit, automatically assume that it is 64 bit and pull from the array.
            $regPath = @(
                'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
                'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            )
        }
        Get-ItemProperty $regPath | .{ process{ if($_.DisplayName -and $_.UninstallString){ $_}}} | Select DisplayName, Publisher, InstallDate, DisplayVersion | Sort DisplayName
    }
}

# [VARIABLES-------------------------------------------------------------------------------------]
#$global:outputFileLocation = "C:\Users\zlundgren\Desktop"
#$stComputers = (Get-ADComputer -SearchBase "ou=store ticket computer,ou=store computers,dc=domain,dc=com" -Filter *).Name; #List of store computers in the AD with name only.
$stComputers = Read-Host "Input computer number/name here" #This makes sure you don't want to populate this script on all computers with the variable right above, just the one you state/write.

# [SCRIPT----------------------------------------------------------------------------------------]
#GetAllStoreComputers

foreach($computer in $stComputers) { #Goes through each $computer in $stComputers and checks if LANDesk Agent is already installed. #If true, it will continue onto the next machine; if not, it will go through the installation.
    $agentCheck = Get-Service -ComputerName $computer -Name "CBA8" #Searches and gets the service of a specified program in the computer.
    
    if($agentCheck -eq $null) { #If the service has been detected, as in already installed/there, continue onto the next computer.
        #Get-Service -ComputerName $computer -Name LDSecSvc
        Append-Log "$computer, already installed." # !!! Gonna have to either move "Append-Log" along these lines & below into a different script because it is going through "-AsJob" and altering efficiency.
        
        continue 

    }else { #If not installed, call the function to run the LDAgent installer.
        Append-Log "$computer is now going through LANDesk Agent setup."
        Install_LanDeskAgent $computer
        $agentRecheck = (Get-Service -computerName $computer -Name LDSecSvc).Status
        
        if($agentRecheck -eq "Running") { #Checks and displays if the agent is running.
            Append-Log "$computer, Installed, Running."
        }else { #If not, displays it as installed and not running.
            Append-Log "$computer, Installed, Not Running."
        }
    }
}

<#
    Meant for dumping any unnecessary scripts/variables/etc. Can always be used for later use and ideas of anything, perhaps everything.
[]=========================================================================================================================================================================================[] 
|----------------------------------------------------------------------[][][][]----[]------[]--[]------[]--[][][][]-------------------------------------------------------------------------|
|----------------------------------------------------------------------[]------[]--[]------[]--[][]--[][]--[]------[]-----------------------------------------------------------------------|
|----------------------------------------------------------------------[]------[]--[]------[]--[]--[]--[]--[]------[]-----------------------------------------------------------------------|
|----------------------------------------------------------------------[]------[]--[]------[]--[]------[]--[][][][]-------------------------------------------------------------------------|
|----------------------------------------------------------------------[]------[]--[]------[]--[]------[]--[]-------------------------------------------------------------------------------|
|----------------------------------------------------------------------[]------[]--[]------[]--[]------[]--[]-------------------------------------------------------------------------------|
|----------------------------------------------------------------------[][][][]------[][][]----[]------[]--[]-------------------------------------------------------------------------------|
[]=========================================================================================================================================================================================[] 


[Under "foreach" loop in the scripting section.]
Figure out why Janet wants to go through SaverGrade on all of the ticketing computers. There is a already existing script that runs on each machine. Missing script? Reasons?
Janet gave OK to remove this as long as it doesn't mess up the process of the task.

$domaingradeCheck = Test-Path "\\$computer\c$\...\v4.20.2017"; #Variable holds the test path of the DomainGrade versions file.

if($domaingradeCheck -eq $true) { #If the path exists, continue to the next command.
    Append-Log "$computer has latest version.";
    continue;
}else { #If it doesn't exist, run the function to copy the file to the computer.
    Append-Log "$computer's DomainGrade needs to be updated.";
    Copy_DomainGrade $computer;

    if($domaingradeCheck -eq $true) { #Used for logging when the file is finished copying.
        Append-Log "$computer has been updated.";
    }
}

[Function]
function Copy_DomainGrade ($storeComputer) { #Tests the existence of the file location. If it ceases to exist, copy the item from the shared folder to the location of DomainGrade.
    $domaingradePath = "\\$storeComputer\c$\...\v4.20.2017";
    
    if(!(Test-Path $domaingradePath)) { #Tests the path of the folder; if ceases to exist, it shall create a new folder then copy the files from the Domain share file to the store computer.
        Copy-Item "F:\SHARE\IS\Help_Desk\Janet's documents\DomainGrade\v4.20.2017" $domaingradePath -Force;
    }
}
#>