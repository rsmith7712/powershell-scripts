# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    Query-GMAPSAPI.ps1

.DESCRIPTION
    Geocodes store addresses from Active Directory store-manager accounts using the Google Maps API and exports UFO_NUMBER, address and latitude/longitude to CSV.

.FUNCTIONALITY
    Geocodes store addresses via the Google Maps API.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$apiKEY = '<apikey>'
$resultsArray = @()
$resultsArray += "UFO_NUMBER, Address, Lat, Long"
$savePath = "C:\Users\user4\desktop\StoreLocation.csv"

$SearchBase = "OU=Store Managers,OU=Store Accounts,DC=Domain,DC=COM"
$Users = Get-ADUser -Filter * -SearchScope OneLevel -SearchBase $SearchBase -Properties StreetAddress,State,PostalCode,Country

ForEach($User in $Users){
    Start-Sleep -Seconds 1
    $UserString = "$($User.StreetAddress),$($User.City),$($User.State)"
    $address = $UserString -replace ' ','+'
    $URI = "https://maps.googleapis.com/maps/api/geocode/json?address=$($address)&key=$($apiKEY)"

    $Response = Invoke-RestMethod -Uri $URI -Method Get -TimeoutSec 10
    
    $Lat = $Response.results.geometry.location.lat
    $Long = $Response.results.geometry.location.lng

    $resultsArray += "$($User.GivenName),$($UserString),$($Lat),$($Long)"
}

try {
    $Stream = [System.IO.StreamWriter] $savePath
    $infoArray | ForEach-Object {
        $Stream.WriteLine($_)
    }
}
finally {
    $Stream.Close()
}