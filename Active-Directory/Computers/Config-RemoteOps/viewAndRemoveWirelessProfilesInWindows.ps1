# LEGAL
<# LICENSE
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
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    viewAndRemoveWirelessProfilesInWindows.ps1

.DESCRIPTION
    View and Remove Wireless Profiles in Windows 10.

.FUNCTIONALITY
    See in-line comments or URL for commplete info.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

    AUTHOR: Doctor Scripto, Sean Kearney
    https://devblogs.microsoft.com/scripting/using-powershell-to-view-and-remove-wireless-profiles-in-windows-10-part-4/

#>

# Capture the list of Wireless profiles by only their names as an Array
$list = ((netsh.exe wlan show profiles) -match '\s{2,}:\s') -replace '.*:\s' , ''

# Purge everything with one loop; Extreme but works
#Foreach ($item in $list){
#     Netsh.exe wlan delete profile $item
#}

## OR ##

# Function to show us the profiles
function Get-WifiProfile {
    [cmdletbinding()]
    param(
        [System.Array]$Name = $NULL
    )

    # Get list of WLAN profiles
    Begin {
        $list = ((netsh.exe wlan show profiles) -match '\s{2,}:\s') -replace '.*:\s' , ''

        # Rebuild array as a PowerShell Customobject
        $ProfileList = $List | Foreach-object { [pscustomobject]@{Name = $_ } }
    }

    # Show profiles which match names in the array
    Process {
        Foreach ($WLANProfile in $Name) {
            $ProfileList | Where-Object { $_.Name -match $WLANProfile }
        }
    }
        
    # If nothing is provided; Return ALL available WLAN Profiles 
    End {
        If ($Name -eq $NULL) {
            $Profilelist
        }
    }
}

<#
# Function to delete defined list of WLAN profiles
function Remove-WifiProfile{
    [cmdletbinding()]
    param(
        [System.Array]$Name=$NULL
    )
    begin{}
    
    # Step through the list of discovered WLAN profiles
    process{
        Foreach ($item in $Name){

            # Purge each individually
            $Result=(netsh.exe wlan delete profile $item)
            
            # Capture results; Display success to console
            if ($Result -match 'deleted'){
                "WifiProfile : $Item Deleted"
            }
            
            # Display failure to console, of if item wasn't found
            else{
                "WifiProfile : $Item NotFound"
            }
        }

    }
}
#>