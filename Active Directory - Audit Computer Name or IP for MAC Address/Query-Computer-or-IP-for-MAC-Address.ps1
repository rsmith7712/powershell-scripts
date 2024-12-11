<#
.LICENSE
    MIT License, Copyright 2024 Richard Smith

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
	
.DESCRIPTION
    Query remote computer or IP address for its associated MAC information

.FUNCTIONALITY   
    -Query remote computer or IP address for its associated MAC information.
	-Display results, if available, in console.
	-If no results available, display nothing.
	-Must perform query in same subnet as resource searching for.

.NOTES
	To run:
	<script name.ps1> -ComputerName Target1, Target2, etc.
		or
    <script name.ps1> -ComputerName Get-ADComputer -Filter *

#>

function Query-MACAddress{
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='ComputerName or Address you want to scan')]
        [String[]]$ComputerName
    )
    Begin{  
    }
    Process{
        foreach($ComputerName2 in $ComputerName){
            $LocalAddress = @("127.0.0.1","localhost",".")
            # Check if ComputerName is a local address, replace it with the computername
            if($LocalAddress -contains $ComputerName2){
                $ComputerName2 = $env:COMPUTERNAME
            }
            # Send ICMP requests to refresh ARP-Cache
            if(-not(Test-Connection -ComputerName $ComputerName2 -Count 2 -Quiet)){
                Write-Warning -Message """$ComputerName2"" is not reachable via ICMP. ARP-Cache could not be refreshed!"
            }
            # Check if ComputerName is already an IPv4-Address, if not... try to resolve it
            $IPv4Address = [String]::Empty
            
            if([bool]($ComputerName2 -as [System.Net.IPAddress])){
                $IPv4Address = $ComputerName2
            }
            else{
                # Get IP from Hostname (IPv4 only)
                try{
                    $AddressList = @(([System.Net.Dns]::GetHostEntry($ComputerName2)).AddressList)
                    foreach($Address in $AddressList){
                        if($Address.AddressFamily -eq "InterNetwork"){					
                            $IPv4Address = $Address.IPAddressToString 
                            break					
                        }
                    }					
                }
                catch{ 
                    if([String]::IsNullOrEmpty($IPv4Address)){
                        Write-Error -Message "Could not resolve IPv4-Address for ""$ComputerName2"". MAC-Address resolving has been skipped. (Try to enter an IPv4-Address instead of the Hostname!)" -Category InvalidData
                        continue
                    }
                }	
            }
            # Try to get MAC from IPv4-Address
            $MAC = [String]::Empty
        
            # +++ ARP-Cache +++
            $Arp_Result = (arp -a).ToUpper()

            foreach($Line in $Arp_Result){
                if($Line.TrimStart().StartsWith($IPv4Address)){
                    # Some regex magic
                    $MAC = [Regex]::Matches($Line,"([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])").Value
                }
            }
            # +++ NBTSTAT +++ (try NBTSTAT if ARP-Cache is empty)                                   
            if([String]::IsNullOrEmpty($MAC)){                           
                $Nbtstat_Result = nbtstat -A $IPv4Address | Select-String "MAC"
                try{
                    $MAC = [Regex]::Matches($Nbtstat_Result, "([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])").Value
                }
                catch{
                    if([String]::IsNullOrEmpty($MAC)){
                        Write-Error -Message "Could not resolve MAC-Address for ""$ComputerName2"" ($IPv4Address). Make sure that your computer is in the same subnet as $ComputerName2 and $ComputerName2 is reachable." -Category ConnectionError
                        continue
                    }
                }
            }
            [String]$Vendor = (Get-MACVendor -MACAddress $MAC | Select-Object -First 1).Vendor 
            [pscustomobject] @{
                ComputerName = $ComputerName2
                IPv4Address = $IPv4Address
                MACAddress = $MAC
                Vendor = $Vendor
            }
        }   
    }
    End{
    }
}