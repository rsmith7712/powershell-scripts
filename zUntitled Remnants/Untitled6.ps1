
## Access is Denied for Get-WmiObject ##


$discovery = Get-ADComputer -Filter *
$results = New-Object System.Collections.ArrayList

ForEach($computer in $discovery){

    $allAdapters = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" -ComputerName $computer.Name
    
    $nics = $allAdapters | Where-Object{$_.DNSDomain -like "*.symetrix.com"}

    ForEach($adapter in $nics){

        $temp = New-Object PSCustomObject -Property @{ComputerName="$($computer.Name)";Adapter="$($adapter.Description)";IPAddress="$($adapter.IPAddress)";MAC="$($adapter.MACAddress)"}
        $results.Add($temp) | Out-Null
    }
}

$results | Select-Object ComputerName,Adapter,MAC,IPAddress | Export-Csv C:\Results\Untitled6.csv -NoTypeInformation