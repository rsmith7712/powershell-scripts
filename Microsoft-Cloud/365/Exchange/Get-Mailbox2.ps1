# Connect to Exchange Online
# https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/connect-to-exchange-online-powershell?view=exchange-ps
Set-ExecutionPolicy RemoteSigned -Force

winrm get winrm/config/client/auth

winrm set winrm/config/client/auth @{Basic="true"}

# Use login <userID>@example.com 
$UserCredential = Get-Credential 

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

# Needed for proxy server 
$ProxyOptions = New-PSSessionOption -ProxyAccessType AutoDetect

Import-PSSession $Session -DisableNameChecking

# Enable access to Exchange Online PowerShell user 
Set-User -Identity user9@example.com -RemotePowerShellEnabled $true

Get-Mailbox

Get-User -ResultSize unlimited -Filter 'RemotePowerShellEnabled -eq $true'

# Name     RecipientType
# Tony Chu UserMailbox

Get-User -ResultSize unlimited | Format-Table -Auto Name,DisplayName,RemotePowerShellEnabled

# Name     DisplayName RemotePowerShellEnabled
# Tony Chu Tony Chu                       True

Get-User -Identity "Tony Chu" | Format-List RemotePowerShellEnabled
# RemotePowerShellEnabled : True

# To Do Set-User Identity 
# https://docs.microsoft.com/en-us/powershell/module/exchange/users-and-groups/set-user?view=exchange-ps

# Clean up
Remove-PSSession $Session

# Source: https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/disable-access-to-exchange-online-powershell?view=exchange-ps