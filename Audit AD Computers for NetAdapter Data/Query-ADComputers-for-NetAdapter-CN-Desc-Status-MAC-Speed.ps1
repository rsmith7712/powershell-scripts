$Computers = Get-ADComputer -Filter '*'

$Results = foreach ($Computer in $Computers) {
    if (Test-Connection -ComputerName $Computer.Name -Quiet -Count '1') {
        Invoke-Command -ComputerName $Computer.Name -ScriptBlock {
            $Adapters = Get-NetAdapter
            foreach ($Adapter in $Adapters) {
                [PSCustomObject]@{
                    'ComputerName' = $using:Computer.Name
                    'Name'        = $Adapter.Name
                    'Description' = $Adapter.InterfaceDescription
                    'Status'      = $Adapter.Status
                    'MacAddress'  = $Adapter.MacAddress
                    'Speed'       = $Adapter.LinkSpeed
                }
            }
        }
    }
    else {
        [PSCustomObject]@{
            'ComputerName' = $Computer.Name
            'Name'        = 'OFFLINE'
            'Description' = 'OFFLINE'
            'Status'      = 'OFFLINE'
            'MacAddress'  = 'OFFLINE'
            'Speed'       = 'OFFLINE'
        }
    }
}

$Results | Export-Csv -Path C:\Results\Reports\NetAdapters2.csv -NoClobber