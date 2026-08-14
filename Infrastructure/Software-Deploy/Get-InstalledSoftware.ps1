function Get-InstalledSoftware { 
    <# 
    .SYNOPSIS 
        Displays a list of installed software. 
 
    .FUNCTIONALITY 
        Computers 
 
    .DESCRIPTION 
        Display a list of installed software for local or remote system. 
        Connects to the registry through WMI.  Compatible with all  
        versions of Windows that uses WMI. 
 
    On 64-bit Windows systems, some installed software has entries in both  
    the 32-bit and 64-bit installed software registries so you might see  
    double entries for some software.  Use Select-Object -Unique Name to  
    return only single entries. 
     
    .PARAMETER ComputerName 
        If defined, run this command on a remote system via WMI. Optional. 
     
    .PARAMETER Credential 
        Pass a set of PSCredentials to the function for accessing remote systems. Optional. 
 
    .EXAMPLE 
        Get-InstalledSoftware | Format-Table -Autosize | Out-File C:\temp\installedSoftware.txt
 
        Description 
    ----------- 
    May returned duplicate entries on 64-bit Windows systems 
 
    .EXAMPLE 
        Get-InstalledSoftware | Select-Object -Unique Name, Version, Vendor, InstallDate | FT -Autosize 
 
    .EXAMPLE 
        Get-InstalledSoftware -Computer 'Computer1', 'Computer2' | Format-Table -Autosize 
 
    .EXAMPLE 
        Get-InstalledSoftware -Computer 'Computer1' -Credential UserName | Format-Table -Autosize 
 
    .EXAMPLE 
        'Computer1', 'Computer2' | Get-InstalledSoftware | Format-Table 
 
    .EXAMPLE 
        $file = "c:\temp\computers.txt" 
 
        $txtfile = "c:\temp\installedsoftware.txt" 
 
        Get-Content $file | Get-InstalledSoftware -Credential UserName | FT -Autosize | Out-File -filepath $txtfile 
 
    .EXAMPLE 
        G$file = "c:\temp\computers.txt" 
 
        $csvfile = "c:\temp\installedsoftware.csv" 
 
        Get-Content $file | Get-InstalledSoftware -Credential username | Export-CSV $csvfile -NoTypeInformation 
 
    .OUTPUTS 
        System.Management.Automation.PSObject 
 
    .NOTES 
        Author: David Garland 
 
    .LINK 
        TBD 
    #>     
    [OutputType('System.Management.Automation.PSObject')] 
    [CmdletBinding()] 
    param( 
 
        [Parameter(Position=0, 
                   ValueFromPipeline = $True, 
                   ValueFromPipelineByPropertyName = $True)] 
        [System.String[]]$ComputerName=$env:COMPUTERNAME, 
         
        [Parameter()] 
        [ValidateNotNull()] 
        [System.Management.Automation.PSCredential] 
        [System.Management.Automation.Credential()] 
        $Credential = [System.Management.Automation.PSCredential]::Empty 
         
    ) 
     
    begin{ 
        #Define properties 
            $properties = 'ComputerName','Name','Version','Vendor','InstallDate' 
             
    } 
 
    process{ 
     
    #Define Local Machine 
        $hklm = 2147483650 
 
    #Define Registry paths for installed software 
        $UninstallRegKeys=@("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",             
             "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")  
 
    foreach($Computer in $ComputerName) { 
        #Connect to Registry via WMI 
        #Note that connections could also be established using the Get-WmiObject command. However, the Get-WmiObject 
        #command proved to not work with older Windows versions 
 
            $path = "\\"+$Computer+"\root\default:stdregprov" 
            $opt = New-Object Management.ConnectionOptions 
            if($Credential -ne [System.Management.Automation.PSCredential]::Empty) { 
                $opt.Username = $Credential.GetNetworkCredential().Domain +"\"+ $Credential.GetNetworkCredential().UserName 
                $opt.Password = $Credential.GetNetworkCredential().Password 
            } 
 
            $scope = New-Object Management.ManagementScope $path, $opt 
            $gopt = New-Object Management.ObjectGetOptions 
 
            $scope.Connect() 
 
            $wmi = New-Object Management.ManagementClass $scope, $path, $gopt 
 
        #Parse through each Uninstall Registry key 
            foreach($UninstallRegKey in $UninstallRegKeys){ 
 
            #Get list of subkeys 
                $regkey = $wmi.EnumKey($hklm,  $UninstallRegKey) 
 
            #Parse through each subkey 
                foreach($key in $regkey.sNames) {  
 
                #Get Values 
                    $name = $wmi.GetStringValue($hklm, $UninstallRegKey+"\"+$key, "DisplayName").sValue 
                    $version = $wmi.GetStringValue($hklm, $UninstallRegKey+"\"+$key, "DisplayVersion").sValue 
                    $vendor = $wmi.GetStringValue($hklm, $UninstallRegKey+"\"+$key, "Publisher").sValue 
                    $installdate = $wmi.GetStringValue($hklm, $UninstallRegKey+"\"+$key, "InstallDate").sValue 
         
                    if(!$name) {continue} 
 
                    if($regkey.PSComputerName -ne $null) { 
                        $Computer = $regkey.PSComputerName 
                    } 
             
                #Write to the object     
                    New-Object -TypeName PSObject -Property @{ 
                        ComputerName = $Computer 
                        Name = $name 
                        Version = $version 
                        Vendor = $vendor 
                        InstallDate = $installdate 
                    } | Select-Object -Property $properties     
                } 
            } 
        } 
    } 
}
