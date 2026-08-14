$ScriptName = $MyInvocation.MyCommand.Name
$rundate = get-date
$logdate = "_"+$rundate.Year+"_"+$rundate.month+"_"+$rundate.Day+"_"+$rundate.hour+"_"+$rundate.minute
$ErrorLog = ".\$ScriptName-ScriptErrors-$logdate.log"
"$(Get-Date) INFO: Logfile initialised" | Add-Content $ErrorLog
 
$table = @()
$source = ".\address.txt"
$addresses = GC -LiteralPath $Source | Measure-Object -Line | Select-Object -ExpandProperty Lines
$count = 0
ForEach ($address in (GC -LiteralPath $Source))
{
$OK = $false
$RetryCount = 0
$PauseCount = 0
do {
    try {
        "$(Get-Date) INFO: Trying to GeoCode $Address" | Add-Content $ErrorLog
        $geocodeurl = "http://maps.googleapis.com/maps/api/geocode/xml?address=$address&sensor=false"
        $result = [xml](new-object System.Net.WebClient).DownloadString($geocodeurl)
        $Returned = $result.GeoCodeResponse.Result.formatted_address
        $LAT = $result.GeoCodeResponse.Result.geometry.location.lat
        $LNG = $result.GeoCodeResponse.Result.geometry.location.lng
            If ($LAT -eq $null -and $PauseCount -lt 3) {
                $OK = $false
                $PauseCount += 1
                "$(Get-Date) WARNING: No LAT/LNG returned, attempt $PauseCount" | Add-Content $ErrorLog
                sleep -s 10
            }
            Else {
                $OK = $true
                If ($PauseCount -gt 2) {
                "$(Get-Date) WARNING: No data returned after 3 attempts, moving on." | Add-Content $ErrorLog
                $LAT = "No data"
                $LNG = "No data"
                }
                Else {
                "$(Get-Date) INFO: Google returned $LAT and $LNG" | Add-Content $ErrorLog
                }
            }
        }
    catch [Net.WebException] {
        If ($RetryCount  -gt 3) {
            $OK = $true
            "$(Get-Date) ERROR: Failed on $Address 3 times, moving on" | Add-Content $ErrorLog
            $LAT = "No data"
            $LNG = "No data"
        }
        else {
            "$(Get-Date) INFO: Sleeping for 10 seconds" | Add-Content $ErrorLog
            sleep -s 10
            $RetryCount += 1
        }
    }
}
While ($OK -eq $false)
 
    $gresult = New-Object System.Object
    $gresult | Add-Member -type NoteProperty -name TargetAddress -value $address
    $gresult | Add-Member -type NoteProperty -name ReturnedAddress -value $returned
    $gresult | Add-Member -type NoteProperty -name Latitude -value $LAT
    $gresult | Add-Member -type NoteProperty -name Longitude -value $LNG
 
    $table += $gresult
    "$(Get-Date) INFO: Added to data table" | Add-Content $ErrorLog
    $count += 1
    if ($count -gt $addresses) {
        $count = $addresses
    }
    Write-Progress -Activity "Geo-Coding Addresses" -status "Percent complete:" -percentComplete (($count / $addresses) *100)
 
}
$table | export-csv ".\results.txt" -NoTypeInformation
"$(Get-Date) INFO: Results exported" | Add-Content $ErrorLog