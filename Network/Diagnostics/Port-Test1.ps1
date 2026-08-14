#$ComputerName = Read-Host "Enter Destination Hostname"
[array]$computers = "srv-lsm-app4"
CLS

# Port Range
#$Ports = 49152..65535

# Port List
# $Ports = "9010"
$Ports = "80","445","137","135"
$source = $env:COMPUTERNAME
$sourceips = [System.Net.Dns]::GetHostAddresses($source) | where {$_.AddressFamily -notlike "InterNetworkV6"}
$sourceip = $sourceips.IPAddressToString
Write-Host "Source: $source ($sourceip)" -ForegroundColor Yellow

#foreach ($Computer in $ComputerName) {
    $computers | foreach{
    $computer = $_
    $Ports | foreach {
        $Port = $_
        $ips = [System.Net.Dns]::GetHostAddresses($computer) | where {$_.AddressFamily -notlike "InterNetworkV6"} 
        
        # Create a Net.Sockets.TcpClient object to use for
        # checking for open TCP ports.
        $Socket = New-Object Net.Sockets.TcpClient
        
        # Suppress error messages
        $ErrorActionPreference = 'SilentlyContinue'
        
        # Try to connect
        $Socket.Connect($Computer, $Port)
        
        # Make error messages visible again
        $ErrorActionPreference = 'Continue'
        $IP = $ips.IPAddressToString

        # Determine if we are connected.
        if ($Socket.Connected) {
            
            Write-Host "Destination: $Computer ($IP) - Port $Port is open" -ForegroundColor Green
            $Socket.Close()
        }
        else {
            Write-Host "Destination: $Computer ($IP) - Port $Port is closed or filtered" -ForegroundColor Red
        }
        # Apparently resetting the variable between iterations is necessary.
        $Socket = $null
    }
}
Write-Host ""
Write-Host ""
Write-Host ""

# pause
