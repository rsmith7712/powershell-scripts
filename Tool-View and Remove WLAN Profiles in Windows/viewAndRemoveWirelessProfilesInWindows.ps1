<#
.NAME
    viewAndRemoveWirelessProfilesInWindows.ps1

.SYNOPSIS
    View and Remove Wireless Profiles in Windows 10

.FUNCTIONALITY
    See in-line comments or URL for commplete info

.AUTHOR
    Doctor Scripto, Sean Kearney

.URL
    https://devblogs.microsoft.com/scripting/using-powershell-to-view-and-remove-wireless-profiles-in-windows-10-part-4/

#>

# Capture the list of Wireless profiles by only their names as an Array
$list=((netsh.exe wlan show profiles) -match '\s{2,}:\s') -replace '.*:\s' , ''

# Purge everything with one loop; Extreme but works
#Foreach ($item in $list){
#     Netsh.exe wlan delete profile $item
#}

## OR ##

# Function to show us the profiles
function Get-WifiProfile{
    [cmdletbinding()]
    param(
        [System.Array]$Name=$NULL
    )

    # Get list of WLAN profiles
    Begin{
        $list=((netsh.exe wlan show profiles) -match '\s{2,}:\s') -replace '.*:\s' , ''

        # Rebuild array as a PowerShell Customobject
        $ProfileList=$List | Foreach-object {[pscustomobject]@{Name=$_}}
        }

        # Show profiles which match names in the array
        Process{
            Foreach ($WLANProfile in $Name){
                $ProfileList | Where-Object {$_.Name -match $WLANProfile}
            }
        }
        
        # If nothing is provided; Return ALL available WLAN Profiles 
        End{
            If ($Name -eq $NULL){
                $Profilelist
            }
        }
    }

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