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
    365 Test Mail via GRAPH.ps1

.DESCRIPTION
    Installs the Microsoft.Graph PowerShell module, connects to Microsoft Graph with the Mail.Send scope, and sends a test email through Send-MgUserMail to validate mail delivery.

.FUNCTIONALITY
    Sends a test email via Microsoft Graph to verify mail-send permissions.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Install the Microsoft Graph PowerShell Module
Install-Module -Name Microsoft.Graph -Scope AllUsers # or CurrentUse

# Verify Module Installation and Path
$env:PSModulePath

# Interactive sign-in (consent Mail.Send the first time)
Connect-MgGraph -Scopes Mail.Send

# Send as the signed-in user:
$message = @{
  Message = @{
    Subject = "Test Email"
    Body = @{ ContentType = "Text"; Content = "Test via Microsoft Graph" }
    ToRecipients = @(@{ EmailAddress = @{ Address = "admin@domain.co" } })
  }
  SaveToSentItems = $true
}

# If you need to send as another mailbox you own/operate, sign in with that account,
# or use app permissions with Send.As (requires Azure AD app + admin consent).
Send-MgUserMail -UserId "svc-mktgweb@domain.co" -BodyParameter $message
