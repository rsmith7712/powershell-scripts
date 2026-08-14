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
    inputboxmessage.ps1

.DESCRIPTION
    Displays a GUI yes/no confirmation message box and input prompt (UI snippet).

.FUNCTIONALITY
    Displays GUI message and input boxes.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


#pop up box and button

$ButtonType = [System.Windows.MessageBoxButton]::YesNo
$MessageboxTitle = "Test pop-up message title"
$Messageboxbody = "Are you sure you want to stop this script execution?"
$MessageIcon = [System.Windows.MessageBoxImage]::Warning
[System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)


$user = "domainuser3"
$title = "AD Administration"
$message = "Do you want to get your USER info now?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "display message now."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Does not display the message now . You will have to display manually later."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $Host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {"You selected Yes."

         Get-ADUser $User -Properties Description

          }
        1 {"You selected No."}
    }














<#
Function Choose-Group
{
    If([string]::IsNullOrEmpty($Script:ServerGroup))
    {
        $title = "AD user status Check"
        $message = "Which task do you wnat to perform?"
    
        $Audit = New-Object System.Management.Automation.Host.ChoiceDescription "Audit", `
            "Checks current AD active status."
    
        $Disable = New-Object System.Management.Automation.Host.ChoiceDescription "Disable", `
            "Disables AD users in the list"
    
        $Enable = New-Object System.Management.Automation.Host.ChoiceDescription "Enable", `
            "Enables AD users in the list."
    
        $AuditExport = New-Object System.Management.Automation.Host.ChoiceDescription "Audit Export", `
            "Exports the audit list"
      
        $Quit = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel", `
            "Quits the script."
    
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($audit,$disable,$enable,$auditexport,$Quit)
    
        $Group = $host.ui.PromptForChoice($title, $message, $options, 4)
    }
    
    Switch ($Group)
    {
        0{Return "00_servers"}
        1{Return "01_servers"}
        2{Return "02_servers"}
        3{Return "DMZ Servers"}
        4{Write-Host "You've chosen to cancel the script.";Exit 1}
        default{Write-Host "You've entered a non-existant Server Group. Script exiting in 5 seconds.";Start-Sleep 5;Exit 1}
    }
}
#>