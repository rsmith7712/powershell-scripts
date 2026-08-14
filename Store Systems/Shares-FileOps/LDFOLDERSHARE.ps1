<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: LDFOLDERSHARE.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format MM.dd.yyyy
$starttime = Get-Date -Format HH:mm:ss
$Script:Logfile = "C:\temp\LDFOLDERS_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Process started on $stamp at $starttime"
function Append-Log($message)
{
    $thetime = get-date -Format HH:mm:ss
	Add-Content $Script:LogFile "$thetime ---- $message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function Set_Permissions_Patch{
    NET SHARE Patch /Delete
    New-Item C:\Patch -ItemType Directory
    $Patch = Get-Item -Path C:\Patch
    $Path = $patch.FullName
    $name = $patch.Name
    $description = "$name"
    $acl = (Get-Item -Path $path).GetAccessControl('Access')
    $everyone = New-Object System.Security.AccessControl.FileSystemAccessRule('Everyone','ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow')
    $ldmsread = New-Object System.Security.AccessControl.FileSystemAccessRule('domain\ldmsread','ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow')
    $ldmswrite = New-Object System.Security.AccessControl.FileSystemAccessRule('domain\ldmswrite','FullControl','ContainerInherit,ObjectInherit','None','Allow')
    $ldmsadmin = New-Object System.Security.AccessControl.FileSystemAccessRule('domain\ldmsadmin','FullControl','ContainerInherit,ObjectInherit','None','Allow')
    $acl.SetAccessRule($everyone)
    $acl.SetAccessRule($ldmsread)
    $acl.SetAccessRule($ldmswrite)
    $acl.SetAccessRule($ldmsadmin)
    Set-Acl -Path $Path -AclObject $acl
    #create share using wmi
    $method = "Create"
    $sd = ([WMIClass] "Win32_securitydescriptor").CreateInstance()
    $ACE = ([WMIClass] "Win32_ACE").CreateInstance()
    $Trustee = ([WMIClass] "Win32_Trustee").CreateInstance()
    $Trustee.Name = "everyone"
    $Trustee.Domain = $Null
    #$Trustee.SID = ([wmi]"win32_userAccount.Domain='$domain',Name='$name'").sid    
    $ace.AccessMask = 2032127
    $ace.AceFlags = 3
    $ace.AceType = 0
    $ACE.Trustee = $Trustee 
    $sd.DACL += $ACE.psObject.baseobject 
    $mc = [WmiClass]"Win32_Share"
    $InParams = $mc.psbase.GetMethodParameters($Method)
    $InParams.Access = $sd
    $InParams.Description = $description
    $InParams.MaximumAllowed = $Null
    $InParams.Name = $name
    $InParams.Password = $Null
    $InParams.Path = $path
    $InParams.Type = [uint32]0
    $R = $mc.PSBase.InvokeMethod($Method, $InParams, $Null)
    switch ($($R.ReturnValue))
     {
          0 {Write-Host "Share:$name Path:$path Result:Success"; break}
          2 {Write-Host "Share:$name Path:$path Result:Access Denied" -foregroundcolor red -backgroundcolor yellow;break}
          8 {Write-Host "Share:$name Path:$path Result:Unknown Failure" -foregroundcolor red -backgroundcolor yellow;break}
          9 {Write-Host "Share:$name Path:$path Result:Invalid Name" -foregroundcolor red -backgroundcolor yellow;break}
          10 {Write-Host "Share:$name Path:$path Result:Invalid Level" -foregroundcolor red -backgroundcolor yellow;break}
          21 {Write-Host "Share:$name Path:$path Result:Invalid Parameter" -foregroundcolor red -backgroundcolor yellow;break}
          22 {Write-Host "Share:$name Path:$path Result:Duplicate Share" -foregroundcolor red -backgroundcolor yellow;break}
          23 {Write-Host "Share:$name Path:$path Result:Reedirected Path" -foregroundcolor red -backgroundcolor yellow;break}
          24 {Write-Host "Share:$name Path:$path Result:Unknown Device or Directory" -foregroundcolor red -backgroundcolor yellow;break}
          25 {Write-Host "Share:$name Path:$path Result:Network Name Not Found" -foregroundcolor red -backgroundcolor yellow;break}
          default {Write-Host "Share:$name Path:$path Result:*** Unknown Error ***" -foregroundcolor red -backgroundcolor yellow;break}
     }
}

function Set_Permissions_Packages{
    NET SHARE Packages /Delete
    New-Item C:\Packages -ItemType Directory
    $Packages = Get-Item -Path C:\Packages
    $Path = $Packages.FullName
    $name = $Packages.Name
    $description = "$name"
    $acl = (Get-Item -Path $path).GetAccessControl('Access')
    $everyone = New-Object System.Security.AccessControl.FileSystemAccessRule('Everyone','ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow')
    $ldmsread = New-Object System.Security.AccessControl.FileSystemAccessRule('domain\ldmsread','ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow')
    $ldmswrite = New-Object System.Security.AccessControl.FileSystemAccessRule('domain\ldmswrite','FullControl','ContainerInherit,ObjectInherit','None','Allow')
    $ldmsadmin = New-Object System.Security.AccessControl.FileSystemAccessRule('domain\ldmsadmin','FullControl','ContainerInherit,ObjectInherit','None','Allow')
    $acl.SetAccessRule($everyone)
    $acl.SetAccessRule($ldmsread)
    $acl.SetAccessRule($ldmswrite)
    $acl.SetAccessRule($ldmsadmin)
    Set-Acl -Path $Path -AclObject $acl
    #create share using wmi
    $method = "Create"
    $sd = ([WMIClass] "Win32_securitydescriptor").CreateInstance()
    $ACE = ([WMIClass] "Win32_ACE").CreateInstance()
    $Trustee = ([WMIClass] "Win32_Trustee").CreateInstance()
    $Trustee.Name = "everyone"
    $Trustee.Domain = $Null
    #$Trustee.SID = ([wmi]"win32_userAccount.Domain='$domain',Name='$name'").sid    
    $ace.AccessMask = 2032127
    $ace.AceFlags = 3
    $ace.AceType = 0
    $ACE.Trustee = $Trustee 
    $sd.DACL += $ACE.psObject.baseobject 
    $mc = [WmiClass]"Win32_Share"
    $InParams = $mc.psbase.GetMethodParameters($Method)
    $InParams.Access = $sd
    $InParams.Description = $description
    $InParams.MaximumAllowed = $Null
    $InParams.Name = $name
    $InParams.Password = $Null
    $InParams.Path = $path
    $InParams.Type = [uint32]0
    $R = $mc.PSBase.InvokeMethod($Method, $InParams, $Null)
    switch ($($R.ReturnValue))
     {
          0 {Write-Host "Share:$name Path:$path Result:Success"; break}
          2 {Write-Host "Share:$name Path:$path Result:Access Denied" -foregroundcolor red -backgroundcolor yellow;break}
          8 {Write-Host "Share:$name Path:$path Result:Unknown Failure" -foregroundcolor red -backgroundcolor yellow;break}
          9 {Write-Host "Share:$name Path:$path Result:Invalid Name" -foregroundcolor red -backgroundcolor yellow;break}
          10 {Write-Host "Share:$name Path:$path Result:Invalid Level" -foregroundcolor red -backgroundcolor yellow;break}
          21 {Write-Host "Share:$name Path:$path Result:Invalid Parameter" -foregroundcolor red -backgroundcolor yellow;break}
          22 {Write-Host "Share:$name Path:$path Result:Duplicate Share" -foregroundcolor red -backgroundcolor yellow;break}
          23 {Write-Host "Share:$name Path:$path Result:Reedirected Path" -foregroundcolor red -backgroundcolor yellow;break}
          24 {Write-Host "Share:$name Path:$path Result:Unknown Device or Directory" -foregroundcolor red -backgroundcolor yellow;break}
          25 {Write-Host "Share:$name Path:$path Result:Network Name Not Found" -foregroundcolor red -backgroundcolor yellow;break}
          default {Write-Host "Share:$name Path:$path Result:*** Unknown Error ***" -foregroundcolor red -backgroundcolor yellow;break}
     }
}

# ----------------------------------------------------------------------------------------------
# Variables

#$computers = @()
#$computers += (Get-ADComputer -Filter * -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com").name 
#$computers += (Get-ADComputer -Filter * -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com").name 
#$computers += (Get-ADComputer -Filter * -SearchBase "ou=store additional computers,ou=store computers,dc=domain,dc=com").name
$computers = Read-Host "Enter Computer Name"
#$computers = Get-Content C:\temp\computers.txt
$domainuser = "domain\opsadmin"
$domainpass = ConvertTo-SecureString "<password>" -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential $domainuser, $domainpass

# ----------------------------------------------------------------------------------------------
# Script

foreach($computer in $computers){
    $connection = Test-Connection -ComputerName $computer -Quiet
    if($connection -eq $false){
        Append-Log "$computer cannot be reached"
    }
    else{
        Invoke-Command -ComputerName $computer -Credential $DomainCred -ScriptBlock ${function:Set_Permissions_Patch}
        Invoke-Command -ComputerName $computer -Credential $DomainCred -ScriptBlock ${function:Set_Permissions_Packages}
        Append-Log "$computer - folders created and shared and permissions set."
    }
}