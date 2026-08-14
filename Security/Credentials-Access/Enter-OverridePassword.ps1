# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    Enter-OverridePassword.ps1

.DESCRIPTION
    Presents GUI message-box and input-box prompts to capture an override password or response.

.FUNCTIONALITY
    Prompts for an override password via GUI.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



Function Launch-MessageBox($msg,$title,$options){ #Prompt the user with a box and return their response
    Add-Type -AssemblyName System.Windows.Forms
    $message = [System.Windows.Forms.MessageBox]::Show($msg,$title,$options)
    return $message
   }

Function Launch-OverrideInputBox($msg,$title){
    Add-Type -AssemblyName Microsoft.VisualBasic
    $script:text = [Microsoft.VisualBasic.Interaction]::InputBox($msg,$title)
    }

Function Enter-OverridePassword{
$prompt = Launch-MessageBox "Wireless Network Not Found or Wireless Declined.`n`nWireless is a requirement for this project.`n`nScript Exiting. `n`nOverride as an administrator and continue?" "Setup Script Error" 4
if($prompt -eq "Yes"){
$passcount = 0
    do {
        $pass = ((Get-Date).DayOfWeek).ToString() + "8675309"
        if($passcount -ge 0){
                            "Code Entered: $text Password Count: $passcount"
                            }
            else{
                Launch-MessageBox "You have entered the incorrect override code.`n`nTry Again..." "Override Failure" 0
                }
                $message = "Attempts: $($passcount)/5`n`n`n`n`n`nEnter Override Code:"
            Launch-OverrideInputBox $message 'Administrator Override Prompt'
            $passcount ++                      
            }
        while (($text -ne $pass) -and ($passcount -lt 6))
        if($passcount -ge 6){
                            Launch-MessageBox "You have entered the incorrect override code too many times.`n`nExiting Script..." "Override Failure" 0
                            EXIT 1
                            }
        }
        Else{
            Launch-MessageBox "You chose not to continue.`n`nExiting..." "Exiting Script" 0
            EXIT 1                
            }
        Launch-MessageBox "SUCCESS! You have entered the correct override code." "Override Success" 0
        #EXIT 0
}
Enter-OverridePassword