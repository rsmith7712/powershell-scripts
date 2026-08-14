function set-homepath
{
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true,
        Position=0)]
        $computer
    )
    #Log_ToSplunk -Message "Setting homepath for users on"
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

    $str = "user3"
    $mgr = "user3admin"
    
    $parentpath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\'
    $SIDs = get-childitem -Path $parentpath | Select-Object -Property pschildname
    
    foreach($SID in $SIDs.pschildname)
    {
        #write-host $sid
        $path = $parentpath + $SID
        write-host $path
        if((Get-ItemProperty -Path $path -Name profileimagepath).profileimagepath.substring(9).trim() -eq ($str -or $mgr))
        {
            Write-Host "MATCH FOUND"
        }
        else 
        {
            #Log_ToSplunk -Message "Did not find $str or $mgr on $computer"
        }
    }

    Remove-PSDrive -Name HKU -Force
}

Invoke-Command -ComputerName "user32vm" -ScriptBlock ${function:set-homepath} -ArgumentList "user32vm"