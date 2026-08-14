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
    Remove-ScheduledTasks_Streamlined.ps1

.DESCRIPTION
    Removes scheduled tasks across target computers (streamlined version, with a console banner).

.FUNCTIONALITY
    Removes scheduled tasks across computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function New-Header{
	Write-Host "=============================================================================="
	Write-Host "                         REMOVE SCHEDULED TASKS                               "
	Write-Host "=============================================================================="
}

Do {
    Clear-Host
    New-Header
    Write-Host ""
    If($Count -ge 1){
        Write-Host "You've entered an invalid UFO_NUMBER.`n" -ForegroundColor Red
        }
    Write-Host "This script will delete the tasks for a Store IP Change."
    $Response = Read-Host "What UFO_NUMBER do you want to do this to?"
    $Test = [RegEx]::IsMatch($Response,"^\d{4}$")
    $Count ++
    }
while($True -ne $Test)

$Store = $Response

Clear-Host
New-Header
Write-Host ""
$Title = "UFO_NUMBER Check"
$message = "Please verify that you wish to run this against Store # $Store."
$option1 = New-Object System.Management.Automation.Host.ChoiceDescription "&No"
$option2 = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($option1, $option2)
$choice = $host.ui.PromptForChoice($Title,$Message,$options,0)

Clear-Host
New-Header
Write-Host ""
Switch($choice){
    0{Write-Host "Script Exiting.";Start-Sleep 5;Exit}
    1{
        #Queries AD for a list of Ticketing Computers and adds the task.
        $GetREG = Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Register Computers,OU=Store Computers,DC=DOMAIN,DC=com"
        $GetSLC = Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=SLC Servers,OU=Store Servers,DC=DOMAIN,DC=com"
        $GetST = Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Computers,OU=Store Computers,DC=DOMAIN,DC=com"
        $GetJS = Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Jumpstart Computers,OU=Store Computers,DC=DOMAIN,DC=com"
        $GetS2 = Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Additional Computers,OU=Store Computers,DC=DOMAIN,DC=com"
        $GetTKT = Get-ADComputer -LDAPFilter "(name=$Store*)" -SearchBase "OU=Store Ticket Computer,OU=Store Computers,DC=DOMAIN,DC=com"

        $Devices = $GetREG.name
        $Devices += $GetSLC.name
        $Devices += $GetST.name
        $Devices += $GetJS.name
        $Devices += $GetS2.name
        $TKTs = $GetTKT.name

        $sb = {
            If (Test-Connection -CN $args -Quiet){  
                SCHTASKS /delete /s $args /TN "IPchange" /f
                SCHTASKS /delete /s $args /TN "IPfailsafe" /f
                Start-Sleep 1
                $Check = schtasks /query /s $args | ?{$_ -like "IPchange" -or $_ -like "IPfailsafe"}
                Switch($Check){
                    $Null{Write-Host "Scheduled Tasks Deleted from $($args)." -ForegroundColor Green}
                    Default{Write-Host "Scheduled Tasks NOT Deleted from $($args)." -ForegroundColor Red}
                    }
                }
            Else{
                Write-Host "$($args) is Offline. Unable to Check Status." -ForegroundColor Red
                }
            }

        Write-Host ""
        Write-Host "Checking Store $Store for IP Conversion Tasks. Please Wait."

        ForEach($Device in $Devices){
            Start-Job -ScriptBlock $sb -ArgumentList $Device | Out-Null
            }
        get-job | wait-job | Receive-Job

        ForEach ($TKT in $TKTs)
        {
            If (Test-Connection -CN $TKT -Quiet)
            {
                #Deletes the new scheduled Task
                SCHTASKS /delete /s $TKT /TN "KillSG" /f
                Start-Sleep 1
                $Check = schtasks /query /s $TKT | ?{$_ -like "KillSG"}
                If($Check -ne $Null){
                    Write-Host "Something went wrong while deleting the scheduled tasks on $TKT." -ForegroundColor Red
                }
                Else{
                    Write-Host "Tasks Deleted from $TKT" -ForegroundColor Green
                }
            }
        }
    }
}