function Test-Port
{
        
    <#
        .Synopsis 
            Test a host to see if the specified port is open.
            
        .Description
            Test a host to see if the specified port is open.
                        
        .Parameter TCPPort 
            Port to test (Default 135.)
            
        .Parameter Timeout 
            How long to wait (in milliseconds) for the TCP connection (Default 3000.)
            
        .Parameter ComputerName 
            Computer to test the port against (Default in localhost.)
            
        .Example
            Test-Port -tcp 3389
            Description
            -----------
            Returns $True if the localhost is listening on 3389
            
        .Example
            Test-Port -tcp 3389 -ComputerName MyServer1
            Description
            -----------
            Returns $True if MyServer1 is listening on 3389
                    
        .OUTPUTS
            System.Boolean
            
        .INPUTS
            System.String
            
        .Link
            Test-Host
            Wait-Port
            
        .Notes
            NAME:      Test-Port
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter()]
        [int]$TCPport = 135,
        [Parameter()]
        [int]$TimeOut = 3000,
        [Alias("dnsHostName")]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [String]$ComputerName = $env:COMPUTERNAME
    )
    Begin 
    {
        Write-Verbose " [Test-Port] :: Start Script"
        Write-Verbose " [Test-Port] :: Setting Error state = 0"
    }
    
    Process 
    {
    
        Write-Verbose " [Test-Port] :: Creating [system.Net.Sockets.TcpClient] instance"
        $tcpclient = New-Object system.Net.Sockets.TcpClient
        
        Write-Verbose " [Test-Port] :: Calling BeginConnect($ComputerName,$TCPport,$null,$null)"
        try
        {
            $iar = $tcpclient.BeginConnect($ComputerName,$TCPport,$null,$null)
            Write-Verbose " [Test-Port] :: Waiting for timeout [$timeout]"
            $wait = $iar.AsyncWaitHandle.WaitOne($TimeOut,$false)
        }
        catch [System.Net.Sockets.SocketException]
        {
            Write-Verbose " [Test-Port] :: Exception: $($_.exception.message)"
            Write-Verbose " [Test-Port] :: End"
            return $false
        }
        catch
        {
            Write-Verbose " [Test-Port] :: General Exception"
            Write-Verbose " [Test-Port] :: End"
            return $false
        }
    
        if(!$wait)
        {
            $tcpclient.Close()
            Write-Verbose " [Test-Port] :: Connection Timeout"
            Write-Verbose " [Test-Port] :: End"
            return $false
        }
        else
        {
            Write-Verbose " [Test-Port] :: Closing TCP Socket"
            try
            {
                $tcpclient.EndConnect($iar) | out-Null
                $tcpclient.Close()
            }
            catch
            {
                Write-Verbose " [Test-Port] :: Unable to Close TCP Socket"
            }
            $true
        }
    }
    End 
    {
        Write-Verbose " [Test-Port] :: End Script"
    }
}