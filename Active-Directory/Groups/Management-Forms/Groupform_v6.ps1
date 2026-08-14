# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    GroupForm_v6_user4.ps1

.SYNOPSIS
  Simple UI to allow users to modify the DisplayNames of Security AND Distribution groups.
 
.DESCRIPTION
  Please see the following URL for the original script.
    https://gallery.technet.microsoft.com/scriptcenter/GUI-for-AD-User-Attribute-b6ac7251
 
.NOTES
  Version:        1.0
  Author:         user26
  Creation Date:  02/01/2018
  Purpose/Change: Modified script to work against groups instead of users. Removed most fields.

.HISTORY

.FUNCTIONALITY
    Please see the following URL for the original script.
        https://gallery.technet.microsoft.com/scriptcenter/GUI-for-AD-User-Attribute-b6ac7251

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Import-Module ActiveDirectory

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 


Function FindADUser ($FindAdUserName)
#####################################
# This function populates the objsearchlistbox with all users that match 
# the criteria specified below. This function also clears the form of any data from previous
# searches and user selections
######################################
{
if ($findadusername -ne ""){
$objSearchListBox.items.clear()

#####################################################
# Getting names of all domains in the forest
###################################################
$objForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$DomainList = @($objForest.Domains | Select-Object Name)
$Domains = $DomainList | foreach {$_.Name}
#####################################################
# Looking for the username in each domain
###########################################
foreach($Domain in ($Domains))
{
	<#
	$ADsPath = [ADSI]"LDAP://$Domain"
	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher($ADsPath)
    #$objSearcher.Filter = "(&(objectClass=group)(!(groupType:1.2.840.113556.1.4.803:=2147483648))(sAMAccountName="+$FindAdUserName+"))"
    $objSearcher.Filter = "(&(objectClass=group)(!(groupType:1.2.840.113556.1.4.803:=2147483648))(|(sAMAccountName="*+$FindAdUserName+")(sAMAccountName="+$FindAdUserName*+")))"
	$objSearcher.SearchScope = "Subtree"
 
    $colResults = $objSearcher.FindAll()
    #>
    $colResults = Get-ADgroup -Filter * -Properties GroupType | Where-Object {$_.GroupType -eq "8" -or $_.GroupType -eq "-2147483640"}
    $colResults = $colResults | Where-Object {$_.name -like "*$FindAdUserName*"}
 	foreach ($objResult in $colResults)
	{
		if ($objResult -ne $null){$objSearchListBox.Items.Add([string]$objResult.distinguishedname)}
	}
}

##############################################################
# FIELD UPDATE - when adding or removing a field to the form -
# the new field needs to be added or removed below for the form to properly clear
############################################################## 
$objmailtxtbox.clear()
$objtargetaddresstxtbox.clear()
$objProxyListBox.items.Clear()
$objproxytxtbox.Clear()
$objext2txtbox.Clear()
$objext3txtbox.clear()
$objext4txtbox.clear()
$objext5txtbox.clear()
$objSelectedUserLabel.text="NONE"
$objselecteduserlabel.backcolor="green"
$objSelectedUserLabel.ForeColor="yellow"
}
}


Function SelectADUser ($dname)
###############################################
# This function loads data into the form for 
# a user selected from the search listbox
# ############################################
{
# If value passed to the function is null - the function will not do anything
if ($dname -ne $null){
$objSelectedUserLabel.text= $dname
$objSelectedUserLabel.BackColor= "red"
$objSelectedUserLabel.ForeColor= "black"
$user=[ADSI]"LDAP://$dname"
##############################################################
# FIELD UPDATE - when adding or removing a field to the form -
# the new field needs to be added or removed below for the form to properly update
#############################################################

$objExt2txtbox.text=$user.properties.displayname
$objext3txtbox.text=$user.properties.name
$objExt4txtbox.text=$user.ExtensionAttribute4
$objExt5txtbox.text=$user.ExtensionAttribute5
$objmailtxtbox.text=$user.mail
$objtargetaddresstxtbox.text=$user.targetaddress

# Once again - check for null values in the proxyaddresses field
if ($user.proxyaddresses -ne $null){
$objProxyListBox.items.clear()
$tempstring = $user.proxyaddresses
#####################################################
# ProxyAddresses is a multi-valued AD attribute, Powershell gets all values
# separated by ";" - the code below splits the string using ; as a delimeter
# and populates each value individually as an item in the objProxyTxtBox
###################################################
$tempProxyAddresses=$tempstring -split ";"
foreach ($tempproxyaddress in $tempProxyAddresses) {$objProxyListBox.items.add($tempproxyaddress)}}
else {$objProxyListBox.items.clear()
$objProxytxtBox.clear()}

$objform.refresh()
$objModifyStatusLabel.Text = "Changes not saved"
$objModifyStatusLabel.backcolor="yellow"
$objModifyStatusLabel.ForeColor="green"
}}

Function ModifyADUser ($dname)
###################################
# This function writes data from textboxes into corresponding 
# user attributes
###############################################
{
# Checking to make sure there is actually a user selected
if ($objSelectedUserLabel.text -ne "NONE"){
$user=[ADSI]"LDAP://$dname"
##############################################################
# FIELD UPDATE - when adding or removing a field to the form -
# the new field needs to be added or removed below for the user to be properly modified
# NOTE - follow the existing "pattern" to enable clearing of user properties via blank textboxes
###############################################################
# Note 2 - for each user we check whether or not the value is null
# if the value is null - we will clear the corresponding attribute in the user's 
# AD account
#############################################################

if ($objext2txtbox.text -ne "") {Set-ADgroup -identity $dname -DisplayName $objext2txtbox.text}

$objModifyStatusLabel.Text = "Changes Saved"
$objModifyStatusLabel.backcolor="green"
$objModifyStatusLabel.ForeColor="yellow"

}}

# Setting up the form
$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Distribution Group Display Name Change"
$objForm.Size = New-Object System.Drawing.Size(635,500) 
$objForm.AutoSize = $True
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True

# Hitting Escape key will close the form
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

##############################################################
# FIELD UPDATE - when adding or removing a field to the form -
# the new field needs to be added or removed below for the form.
# Copy existing textbox and label and paste them, then modify
# the textbox name, the label name, and their vertical location
# to keep the form looking uniform - use multiple of 30's for vertical location
# The order in which objects are added to the form here determines the order in which TAB key
# will move cursor through the form, so place new fields accordingly!
################################################################

# Below we add buttons, text boxes, etc, etc

$FindButton = New-Object System.Windows.Forms.Button
$FindButton.Location = New-Object System.Drawing.Size(195,60)
$FindButton.Size = New-Object System.Drawing.Size(75,23)
$FindButton.Text = "Find"
$FindButton.Add_Click({FindADUser $objTextBox.Text})
$objForm.Controls.Add($FindButton)

$CloseButton = New-Object System.Windows.Forms.Button
$CloseButton.Location = New-Object System.Drawing.Size(20,430)
$CloseButton.Size = New-Object System.Drawing.Size(75,23)
$CloseButton.Text = "Close"
$CloseButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CloseButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(280,20) 
$objLabel.Text = "Group Name:"
$objForm.Controls.Add($objLabel) 

$objModifyStatusLabel = New-Object System.Windows.Forms.Label
$objModifyStatusLabel.Location = New-Object System.Drawing.Size(310,400) 
$objModifyStatusLabel.Size = New-Object System.Drawing.Size(150,20) 
$objForm.Controls.Add($objModifyStatusLabel)

$objListLabel = New-Object System.Windows.Forms.Label
$objListLabel.Location = New-Object System.Drawing.Size(10,85) 
$objListLabel.Size = New-Object System.Drawing.Size(280,20) 
$objListLabel.Text = "Search Results:"
$objForm.Controls.Add($objListLabel) 

$SelectUserButton = New-Object System.Windows.Forms.Button
$SelectUserButton.Location = New-Object System.Drawing.Size(195,400)
$SelectUserButton.Size = New-Object System.Drawing.Size(75,23)
$SelectUserButton.Text = "Select"
$SelectUserButton.Add_Click({SelectADUser $objSearchListBox.SelectedItem;})
$objForm.Controls.Add($SelectUserButton)

$objTextBox = New-Object System.Windows.Forms.TextBox 
$objTextBox.Location = New-Object System.Drawing.Size(10,40) 
$objTextBox.Size = New-Object System.Drawing.Size(260,20)
$objTextBox.focus()
$objTextBox.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        { FindADUser $objTextBox.Text; }})
$objForm.Controls.Add($objTextBox) 

$objSearchListBox = New-Object System.Windows.Forms.ListBox 
$objSearchListBox.Location = New-Object System.Drawing.Size(10,105) 
$objSearchListBox.Size = New-Object System.Drawing.Size(260,20) 
$objSearchListBox.Height = 300
$objSearchListBox.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        {SelectADUser $objSearchListBox.SelectedItem}})
$objSearchListBox.add_DoubleClick({SelectADUser $objSearchListBox.SelectedItem})

$objForm.Controls.Add($objSearchListBox)

$objSelectedUser2Label = New-Object System.Windows.Forms.Label
$objSelectedUser2Label.Location = New-Object System.Drawing.Size(310,0) 
$objSelectedUser2Label.Size = New-Object System.Drawing.Size(90,15) 
$objSelectedUser2Label.text="Group Selected:"
$objForm.Controls.Add($objSelectedUser2Label) 

$objSelectedUserLabel = New-Object System.Windows.Forms.Label
$objSelectedUserLabel.Location = New-Object System.Drawing.Size(310,20) 
$objSelectedUserLabel.Size = New-Object System.Drawing.Size(300,60) 
$objSelectedUserLabel.text="NONE"
$objSelectedUserLabel.backcolor="green"
$objSelectedUserLabel.forecolor="yellow"
$objForm.Controls.Add($objSelectedUserLabel) 

$objExt2Label = New-Object System.Windows.Forms.Label
$objExt2Label.Location = New-Object System.Drawing.Size(310,90) 
$objExt2Label.Size = New-Object System.Drawing.Size(120,20) 
$objExt2Label.Text="Display Name"
$objForm.Controls.Add($objExt2Label)

$objext2txtbox = new-object System.Windows.Forms.TextBox
$objext2txtbox.location = New-Object System.Drawing.Size(430,90)
$objext2txtbox.size = new-object system.drawing.size(140,20)
$objform.controls.add($objext2txtbox)

<#
$objExt3Label = New-Object System.Windows.Forms.Label
$objExt3Label.Location = New-Object System.Drawing.Size(310,120) 
$objExt3Label.Size = New-Object System.Drawing.Size(120,20) 
$objExt3Label.Text="Name"
$objForm.Controls.Add($objExt3Label) 

$objext3txtbox = new-object System.Windows.Forms.TextBox
$objext3txtbox.location = New-Object System.Drawing.Size(430,120)
$objext3txtbox.size = new-object system.drawing.size(140,20)
$objform.controls.add($objext3txtbox)
#>

$ModifyUserButton = New-Object System.Windows.Forms.Button
$ModifyUserButton.Location = New-Object System.Drawing.Size(490,400)
$ModifyUserButton.Size = New-Object System.Drawing.Size(75,23)
$ModifyUserButton.Text = "Modify"
$ModifyUserButton.Add_Click({ModifyADUser $objSelectedUserLabel.Text;})
$objForm.Controls.Add($ModifyUserButton)


$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate(); $objtextbox.focus()})
[void] $objForm.ShowDialog()



