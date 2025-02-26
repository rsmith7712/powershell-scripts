###
# Fully remove any conflicting or partially created Entra sync account
###

# Install AzureAD Module
#DEPRECATED -- Install-Module -Name AzureAD

# Import the Module
#DEPRECATED -- Import-Module AzureAD
Import-Module Microsoft.Graph.Users

# Connect to Azure AD
#DEPRECATED -- Connect-AzureAD
Connect-MgGraph

# Get all users
Get-MgUser

# Retrieve Deleted Users
#DEPRECATED -- Get-AzureADDeletedUser

# Identify the Sync Account
#DEPRECATED -- Get-AzureADDeletedUser | Where-Object { $_.UserPrincipalName -like "*<partial or full sync account name>*" }

# Purge the Deleted User: Once you have the ObjectId:
#DEPRECATED -- Remove-AzureADDeletedUser -ObjectId "<ObjectId-of-sync-account>"
