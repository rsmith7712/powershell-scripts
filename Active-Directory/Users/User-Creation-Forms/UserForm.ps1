###########################################################################
#   Disclaimer : The sample scripts are not supported under any Microsoft
#                standard support program or service. The sample scripts
#                are provided AS IS without warranty of any kind.
#                Microsoft further disclaims all implied warranties
#                including, without limitation, any implied warranties of
#                merchantability or of fitness for a particular purpose.
#                The entire risk arising out of the use or performance of
#                the sample scripts and documentation remains with you. In
#                no event shall Microsoft, its authors, or anyone else
#                involved in the creation, production, or delivery of the
#                scripts be liable for any damages whatsoever (including,
#                without limitation, damages for loss of business profits,
#                business interruption, loss of business information, or
#                other pecuniary loss) arising out of the use of or
#                inability to use the sample scripts or documentation,
#                even if Microsoft has been advised of the possibility of
#                such damages.
###########################################################################

Import-Module ActiveDirectory

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

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
	
	$ADsPath = [ADSI]"LDAP://$Domain"
	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher($ADsPath)
   	$objSearcher.Filter = "(&(objectCategory=Person)(objectClass=user)(sAMAccountName="+$FindAdUserName+"))"
	$objSearcher.SearchScope = "Subtree"
 
	$colResults = $objSearcher.FindAll()
 	foreach ($objResult in $colResults)
	{
		$FoundUser = $objResult.GetDirectoryEntry()
		if ($FoundUser -ne $null){$objSearchListBox.Items.Add([string]$FoundUser.distinguishedname)}
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

$objExt2txtbox.text=$user.ExtensionAttribute2
$objext3txtbox.text=$user.ExtensionAttribute3
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

if ($objext2txtbox.text -ne "") {$user.put("ExtensionAttribute2", $objext2txtbox.text)} else {$user.extensionattribute2.clear()}
if ($objext3txtbox.text -ne "") {$user.put("ExtensionAttribute3", $objext3txtbox.text)} else {$user.extensionattribute3.clear()}
if ($objext4txtbox.text -ne "") {$user.put("ExtensionAttribute4", $objext4txtbox.text)} else {$user.extensionattribute4.clear()}
if ($objext5txtbox.text -ne "") {$user.put("ExtensionAttribute5", $objext5txtbox.text)} else {$user.extensionattribute5.clear()}
if ($objmailtxtbox.Text -ne "") {$user.put("mail", $objmailtxtbox.Text)} else {$user.mail.clear()}
if ($objtargetaddresstxtbox.Text -ne "") {$user.put("targetaddress", $objtargetaddresstxtbox.Text)} else {$user.targetaddress.clear()}

$user.SetInfo() 
set-aduser -identity $dname -clear proxyAddresses
foreach ($item in $objProxyListBox.items){set-aduser -Identity $dname -add @{proxyAddresses=@($item)}}

$objModifyStatusLabel.Text = "Changes Saved"
$objModifyStatusLabel.backcolor="green"
$objModifyStatusLabel.ForeColor="yellow"

}}

# Setting up the form
$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "User Update"
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
$objLabel.Text = "UserName:"
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
$objSelectedUser2Label.text="User Selected:"
$objForm.Controls.Add($objSelectedUser2Label) 


$objSelectedUserLabel = New-Object System.Windows.Forms.Label
$objSelectedUserLabel.Location = New-Object System.Drawing.Size(310,20) 
$objSelectedUserLabel.Size = New-Object System.Drawing.Size(300,30) 
$objSelectedUserLabel.text="NONE"
$objSelectedUserLabel.backcolor="green"
$objSelectedUserLabel.forecolor="yellow"
$objForm.Controls.Add($objSelectedUserLabel) 


$objExt2Label = New-Object System.Windows.Forms.Label
$objExt2Label.Location = New-Object System.Drawing.Size(310,60) 
$objExt2Label.Size = New-Object System.Drawing.Size(120,20) 
$objExt2Label.Text="ExtensionAttribute2"
$objForm.Controls.Add($objExt2Label) 

$objext2txtbox = new-object System.Windows.Forms.TextBox
$objext2txtbox.location = New-Object System.Drawing.Size(430,60)
$objext2txtbox.size = new-object system.drawing.size(140,20)
$objform.controls.add($objext2txtbox)

$objExt3Label = New-Object System.Windows.Forms.Label
$objExt3Label.Location = New-Object System.Drawing.Size(310,90) 
$objExt3Label.Size = New-Object System.Drawing.Size(120,20) 
$objExt3Label.Text="ExtensionAttribute3"
$objForm.Controls.Add($objExt3Label) 

$objext3txtbox = new-object System.Windows.Forms.TextBox
$objext3txtbox.location = New-Object System.Drawing.Size(430,90)
$objext3txtbox.size = new-object system.drawing.size(140,20)
$objform.controls.add($objext3txtbox)

$objExt4Label = New-Object System.Windows.Forms.Label
$objExt4Label.Location = New-Object System.Drawing.Size(310,120) 
$objExt4Label.Size = New-Object System.Drawing.Size(120,20) 
$objExt4Label.Text="ExtensionAttribute4"
$objForm.Controls.Add($objExt4Label) 

$objext4txtbox = new-object System.Windows.Forms.TextBox
$objext4txtbox.location = New-Object System.Drawing.Size(430,120)
$objext4txtbox.size = new-object system.drawing.size(140,20)
$objform.controls.add($objext4txtbox)


$objExt5Label = New-Object System.Windows.Forms.Label
$objExt5Label.Location = New-Object System.Drawing.Size(310,150) 
$objExt5Label.Size = New-Object System.Drawing.Size(120,20) 
$objExt5Label.Text="ExtensionAttribute5"
$objForm.Controls.Add($objExt5Label) 

$objext5txtbox = new-object System.Windows.Forms.TextBox
$objext5txtbox.location = New-Object System.Drawing.Size(430,150)
$objext5txtbox.size = new-object system.drawing.size(140,20)
$objform.controls.add($objext5txtbox)



$objproxytxtLabel = New-Object System.Windows.Forms.Label
$objproxytxtLabel.Location = New-Object System.Drawing.Size(310,180) 
$objproxytxtLabel.Size = New-Object System.Drawing.Size(120,20) 
$objproxytxtLabel.Text="proxyAddresses"
$objForm.Controls.Add($objproxytxtLabel) 

$objproxytxtbox = new-object System.Windows.Forms.TextBox
$objproxytxtbox.location = New-Object System.Drawing.Size(310,200)
$objproxytxtbox.size = new-object system.drawing.size(200,20)
$objform.controls.add($objproxytxtbox)

$AddProxyAddressButton = New-Object System.Windows.Forms.Button
$AddProxyAddressButton.Location = New-Object System.Drawing.Size(520,200)
$AddProxyAddressButton.Size = New-Object System.Drawing.Size(50,20)
$AddProxyAddressButton.Text = "Add "
$AddProxyAddressButton.Add_Click({if ($objproxytxtbox.text -ne ""){$objProxyListBox.items.add($objproxytxtbox.text);$objproxytxtbox.Clear()}})
$objForm.Controls.Add($AddProxyAddressButton)

$objProxyListBox = New-Object System.Windows.Forms.ListBox 
$objProxyListBox.Location = New-Object System.Drawing.Size(310,220) 
$objProxyListBox.Size = New-Object System.Drawing.Size(260,20) 
$objProxyListBox.Height = 90
$objForm.Controls.Add($objProxyListBox)



$DeleteProxyAddressButton = New-Object System.Windows.Forms.Button
$DeleteProxyAddressButton.Location = New-Object System.Drawing.Size(450,300)
$DeleteProxyAddressButton.Size = New-Object System.Drawing.Size(120,25)
$DeleteProxyAddressButton.Text = "Delete proxyAddress"
$DeleteProxyAddressButton.Add_Click({$objProxyListBox.items.removeAt($objProxyListBox.SelectedIndex);})
$objForm.Controls.Add($DeleteProxyAddressButton)

$objmailtxtbox = new-object System.Windows.Forms.TextBox
$objmailtxtbox.location = New-Object System.Drawing.Size(430,330)
$objmailtxtbox.size = new-object system.drawing.size(140,20)
$objform.controls.add($objmailtxtbox)


$objmailLabel = New-Object System.Windows.Forms.Label
$objmailLabel.Location = New-Object System.Drawing.Size(310,330) 
$objmailLabel.Size = New-Object System.Drawing.Size(120,20) 
$objmailLabel.Text="mail"
$objForm.Controls.Add($objmailLabel) 

$objtargetaddresstxtbox = new-object System.Windows.Forms.TextBox
$objtargetaddresstxtbox.location = New-Object System.Drawing.Size(430,360)
$objtargetaddresstxtbox.size = new-object system.drawing.size(140,20)
$objform.controls.add($objtargetaddresstxtbox)


$objtargetaddressLabel = New-Object System.Windows.Forms.Label
$objtargetaddressLabel.Location = New-Object System.Drawing.Size(310,360) 
$objtargetaddressLabel.Size = New-Object System.Drawing.Size(120,20) 
$objtargetaddressLabel.Text="targetaddress"
$objForm.Controls.Add($objtargetaddressLabel) 

$ModifyUserButton = New-Object System.Windows.Forms.Button
$ModifyUserButton.Location = New-Object System.Drawing.Size(490,400)
$ModifyUserButton.Size = New-Object System.Drawing.Size(75,23)
$ModifyUserButton.Text = "Modify"
$ModifyUserButton.backcolor = "red"
$ModifyUserButton.Add_Click({ModifyADUser $objSelectedUserLabel.Text;})
$objForm.Controls.Add($ModifyUserButton)


$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate(); $objtextbox.focus()})
[void] $objForm.ShowDialog()

