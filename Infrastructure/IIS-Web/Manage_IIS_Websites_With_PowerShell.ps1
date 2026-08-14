# How To Manage IIS Websites With PowerShell

# http://www.tomsitpro.com/articles/powershell-manage-iis-websites,2-994.html

<#
You'll need to ensure you've got PowerShell 
remoting configured and the appropriate firewall 
ports allowed on the server. The quickest way to
do to this is by running "winrm quickconfig" on
the server.
#>

#Install PowerShellGet Module to install latest cmdlts
#available for IIS administration
Install-Module –Name PowerShellGet –Force


# see if we have any websites on our IIS server
Get-Website

<#
To create a website for a web application being 
built. First create a folder, then use the 
New-WebSite cmdlet to specify a name for the website 
and where to place it on the filesystem. 
By default, it creates the website as stopped and 
sets a HTTP binding on port 80.
#>
New-Website –Name TurnOffForMaintenancePage –PhysicalPath C:\inetpub\TurnOffForMaintenancePage

# To start the new website
Get-Website –Name MyWebApp | Start-Website

# If error is encountered due to port 80 binding
# run the following:
Get-Website |
    Where{($_.bindings.collection.protocol -eq 'http') -and
    ($_.bindings.collection.bindingInfo -eq '*:80:')
}

# Stop specific website (this example is for Default Website)
Get-Website -Name 'Default Web Site' | Stop-Website

