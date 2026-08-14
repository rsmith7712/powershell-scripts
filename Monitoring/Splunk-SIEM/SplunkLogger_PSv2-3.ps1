function Log_ToSplunk{
    Param(
    [parameter(Mandatory=$true,
    Position=0)]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
    $ID = $Null
    )
    $product = "team_" + $Script:ProductName
    $uri = "https://hecext.example.com:18443/services/collector/event"
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.add('Authorization', 'Splunk Application-Key-Here')
    $body = @{
        sourcetype = 'domain:ps:log'
        host = $env:COMPUTERNAME
        event = @{
            message = $Message
            user = $env:USERNAME
            product = $Product
            type = $Type
            status = $Status
            id = $ID
        }
    }
    If($($PSVersionTable.PSVersion.Major) -gt 3){
        $body = $body | ConvertTo-Json
        Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
    }
    Else
    {
        $body = $body | ConvertTo-STJson
        $SB = { 
            param($body, $uri)
            $request = [System.Net.WebRequest]::Create($uri)
            $request.ContentType = "application/json"
            $request.Method = "POST"
            $request.Headers.Add('Authorization', 'Splunk Application-Key-Here')
            try
            {
                $requestStream = $request.GetRequestStream()
                $streamWriter = New-Object System.IO.StreamWriter($requestStream)
                $streamWriter.Write($body)
            }
            finally
            {
                if ($null -ne $streamWriter) { $streamWriter.Dispose() }
                if ($null -ne $requestStream) { $requestStream.Dispose() }
            }
        $res = $request.GetResponse()
    }

    $timeout = 30
    $job = Start-Job -ScriptBlock $SB -ArgumentList @($body, $uri)
    Wait-Job $job -Timeout $timeout
    Stop-Job $job
    Receive-Job $job
    Remove-Job $job
    }
}