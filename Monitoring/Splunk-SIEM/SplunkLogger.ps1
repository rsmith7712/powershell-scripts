function Log_ToSplunk($message, $product, $type, $status)
{
    $product = "team_" + $product
    [int]$eventid = $null
    $uri = "https://hecext.example.com:18443/services/collector/event"
    $header = @{}
    $header.add('Content-Type', 'application/json')
    $header.add('Authorization', 'Splunk Application-Key-Here')
    $body = @{
        sourcetype = 'domain:ps:log'
        host = $env:COMPUTERNAME
        event = @{
            message = $message
            user = $env:USERNAME
            product = $product
            type = $type
            eventid = $eventid
        }
    }
    $body = $body | ConvertTo-Json
    Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}

### LEGEND ###
#
# Message: short description of action
# 
# Product: Name of script/program/function.  Always prefaced with "team_"
#
# Type: type of event
# Allowed "types" are as follows:
#   log
#   begin
#   end
#
# Status: 
#   success
#   fail
#   warning
#
### END LEGEND ###