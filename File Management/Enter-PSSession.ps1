# Option 1: Using Get-Credential
$cred = Get-Credential

        # Option 2: Manual credential creation
        #$username = "Administrator"
        #$password = ConvertTo-SecureString "YourPassword" -AsPlainText -Force
        #$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $password

#Enter-PSSession -ComputerName Shipping-Ws2 -Credential $cred   #Shipping Backup Workstation

Enter-PSSession -ComputerName JFU-LT01 -Credential $cred       #OS
