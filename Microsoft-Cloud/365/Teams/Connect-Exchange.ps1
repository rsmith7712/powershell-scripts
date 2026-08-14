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
    Connect-Exchange.ps1

.DESCRIPTION
    Creates and imports a remote PowerShell session to the on-premises hybrid Exchange Client Access server, with status and error handling.

.FUNCTIONALITY
    Establishes a remote Exchange management session.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Set-ExchangeServerSession($cred)
{
    # Creates and imports a session to the exchange hybrid server.
    Write-Host "[STATUS] : Creating Session on Hybrid Exchange Server"
    $ErrorActionPreference = "Stop"
    Try
    {
        $cassession = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri https://srv-exh-cas1.example.com/powershell -Credential $cred -Authentication Basic -AllowRedirection
        if($? -eq $false)
        {
            Write-Host -message "[ERROR] : Error encountered while attempting to create a new PS session on 'srv-exh-cas1.example.com' Exchange server.`nExiting Script...";Exit
        }
            else 
            {
                Write-Host "[SUCCESS] : PS session created successfully on 'srv-exh-cas1.example.com' Exchange server." 
            }
    }
        Catch
        {
            Write-Host -message "[ERROR] : Error encountered while attempting to create a new PS session on 'srv-exh-cas1.example.com' Exchange server.`nException Message: $($_.Exception.Message).`nExiting script..."
            Start-Sleep -Seconds 05
            Exit
        }
    Try
    {
        Import-PSSession $cassession -AllowClobber
        if($? -eq $false)
        {
            Write-Host "[ERROR] : Failed to import CAS Session.`n`nExiting Script..."
        }
            else 
            {
                Write-Host "[SUCCESS] : PS session on 'srv-exh-cas1.example.com' Exchange server successfully imported."
            }
    }
        Catch
        {
            Write-Host -message "[ERROR] : Error encountered while attempting to create a new PS session on 'srv-exh-cas1.example.com'.`nException Message: $($_.Exception.Message).`nExiting script..."
            Start-Sleep -Seconds 05
            Exit
        }
        $ErrorActionPreference = "SilentlyContinue"
}#===================[End Function]===================
Function New-User ($firstname,$lastname,$useralias,$userpassword,$upn,$name)
{
    Clear-Host
    Write-Host $script:BANNER  -ForegroundColor Blue -BackgroundColor White
    Try
    {
        New-RemoteMailbox -Firstname $firstname -Lastname $lastname -Alias $useralias -Password $userpassword -UserPrincipalName $upn -Name $name -DisplayName $name
        Write-Host -message "[SUCCESS] : User AD account creation was successful."
    }
        Catch
        {
            Write-Host "[ERROR] : The following exception was encountered: $($_.Exception.Message)."
        }    
}#===================[End Function]===================
Function Remove-Sessions()
{
    Try
    {
        Get-PSSession | Remove-PSSession
        Write-Host "[SUCCESS] : PS session connection to msonline service successfully terminated." -color "Green"
    }
        Catch
        {
            Write-Host "[ERROR] : Unable to terminate the PSSession to the Exchange server. The following exception was encountered: $($_.Exception.Message)." -color "Red"
        }
}#===================[End Function]===================


$cred = Get-Credential -Message "Enter your administrative user credentials (e.g., UsernameAdmin@example.com)" -UserName "$($env:USERNAME)@example.com"
#$credcheck = ValidEmailAddress $cred.UserName
Set-ExchangeServerSession($cred)
Get-RemoteMailbox -Identity "user2"