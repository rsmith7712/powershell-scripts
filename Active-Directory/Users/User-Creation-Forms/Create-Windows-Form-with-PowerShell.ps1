<#
.NAME
    Create-Windows-Form-with-PowerShell.ps1

.URL
    https://theitbros.com/powershell-gui-for-scripts/
#>

<#
Use the .NET functionality to create forms, we will use the 
class System.Windows.Forms. To load this class into a PowerShell
session, you can use the following code:
#>
Add-Type -assembly System.Windows.Forms

<#
Now create the screen form (window) to contain elements:
#>
$main_form = New-Object System.Windows.Forms.Form

<#
Set the title and size of the window:
#>
$main_form.Text ='GUI for my PoSh script'
$main_form.Width = 600
$main_form.Height = 400

<#
If the elements on the form are out of window bounds, use
the AutoSize property to make the form automatically stretch.
#>
$main_form.AutoSize = $true

<#
Now you can display the form on the screen.
#>
$main_form.ShowDialog()

<#
Create a label element on the form:
#>
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "AD users"
$Label.Location  = New-Object System.Drawing.Point(0,10)
$Label.AutoSize = $true
$main_form.Controls.Add($Label)

<#
Create a drop-down list and fill it with a list of accounts
from the Active Directory domain. You can get the AD user
list using the Get-ADuser cmdlet (from Active Directory for
Windows PowerShell module):
#>
$ComboBox = New-Object System.Windows.Forms.ComboBox
$ComboBox.Width = 300
$Users = get-aduser -filter * -Properties SamAccountName
Foreach ($User in $Users){
$ComboBox.Items.Add($User.SamAccountName);
}
$ComboBox.Location  = New-Object System.Drawing.Point(60,10)
$main_form.Controls.Add($ComboBox)

<#
Add two more labels to the form. The second will show the
time of the last password change for the selected user
account:
#>
$Label2 = New-Object System.Windows.Forms.Label
$Label2.Text = "Last Password Set:"
$Label2.Location  = New-Object System.Drawing.Point(0,40)
$Label2.AutoSize = $true
$main_form.Controls.Add($Label2)
$Label3 = New-Object System.Windows.Forms.Label
$Label3.Text = ""
$Label3.Location  = New-Object System.Drawing.Point(110,40)
$Label3.AutoSize = $true
$main_form.Controls.Add($Label3)

<#
Now put the button on the form:
#>
$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Size(400,10)
$Button.Size = New-Object System.Drawing.Size(120,23)
$Button.Text = "Check"
$main_form.Controls.Add($Button)

<#
The following code will be executed when the user clicks
on the button. To convert the date from the TimeStamp
format to the more convenient form, we use the function
[datetime]::FromFileTime:
#>
$Button.Add_Click({
$Label3.Text =  [datetime]::FromFileTime((Get-ADUser -identity $ComboBox.selectedItem -Properties pwdLastSet).pwdLastSet).ToString('MM dd yy : hh ss')
})

<#
If you want to hide some of the GUI elements on a
Windows Form, use the Visible property. For instance:
#>
$Label3.Text.Visible = $false
# or $True if you want to show it

