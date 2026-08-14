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
    Inventory.ps1

.DESCRIPTION
    Collects a hardware and software inventory (operating system, BIOS, network configuration) from computers via WMI.

.FUNCTIONALITY
    Collects WMI hardware and software inventory.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$ErrorActionPreference = 'SilentlyContinue'

Function Get-Inventory {

PROCESS {


$os = Get-WmiObject Win32_OperatingSystem –computer $_

$bios = Get-WmiObject Win32_BIOS –computer $_

$Network = Get-WmiObject win32_networkadapterconfiguration -Filter 'DHCPEnabled = "true"' –computer $_

$make = get-wmiobject win32_computersystem –computer $_

$processor = Get-WmiObject Win32_Processor -computer $_

$mem = get-wmiobject win32_computersystem -computer $_

$disk = Get-WmiObject Win32_LogicalDisk -ComputerName $_ -Filter "DeviceID='C:'" | Select-Object Size

$output = New-Object PSObject

$output | Add-Member NoteProperty ComputerName $_

$output | Add-Member NoteProperty MACAddress ($Network.MACAddress)

$output | Add-Member NoteProperty Processor ($processor.name)

$output | Add-Member NoteProperty Memory ([math]::round($mem.totalphysicalmemory/1GB))

$output | Add-Member NoteProperty Model ($make.Model)

$output | Add-Member NoteProperty User ($make.username)

$output | Add-Member NoteProperty BIOSSerial ($bios.SerialNumber)

$output | Add-Member NoteProperty 32/64BitOS ($os.OSArchitecture)

Write-Output $output

}

}



function GenerateForm {


#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion

#region Generated Form Objects
$CEITInventory = New-Object System.Windows.Forms.Form
$label2 = New-Object System.Windows.Forms.Label
$SearchBox = New-Object System.Windows.Forms.TextBox
$SearchButton = New-Object System.Windows.Forms.Button
$label1 = New-Object System.Windows.Forms.Label
$textBox1 = New-Object System.Windows.Forms.TextBox
$OKbutton1 = New-Object System.Windows.Forms.Button
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#Generated Form Objects
#assign filter
$SearchBox.Text = $Filter


$OKbutton1_OnClick= 
{
 $outputfile = $env:USERPROFILE + "\desktop\Inventory_Single.CSV"
 $textBox1.Text | Get-Inventory | Export-CSV $outputfile

}


Import-Module ActiveDirectory
$SearchButton_OnClick= 
{
	$ErrorActionPreference = "SilentlyContinue" 
	
	# Setup some parameters
	
    $searchbase = "OU=Domain Servers,DC=Domain,DC=com"
    $filter = "*" + $SearchBox.Text + "*"
	$outputfile = $env:USERPROFILE + "\desktop\Inventory_Group.CSV"
	
	
	# Grab computers
	
         $computers = @(Get-ADComputer -SearchBase $searchbase -Filter {Name -like $filter} | Select-Object -ExpandProperty Name) | Get-Inventory | Export-Csv $outputfile
         
       
	}

$OnLoadForm_StateCorrection=
{#Initial state of form
	$CEITInventory.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#form
$CEITInventory.BackColor = [System.Drawing.Color]::FromArgb(255,9,28,90)
$CEITInventory.BackgroundImageLayout = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 178
$System_Drawing_Size.Width = 345
$CEITInventory.ClientSize = $System_Drawing_Size
$CEITInventory.DataBindings.DefaultDataSourceUpdateMode = 0
$CEITInventory.ForeColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 216
$System_Drawing_Size.Width = 361
$CEITInventory.MaximumSize = $System_Drawing_Size
$CEITInventory.MinimizeBox = $False
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 216
$System_Drawing_Size.Width = 361
$CEITInventory.MinimumSize = $System_Drawing_Size
$CEITInventory.Name = "CEITInventory"
$CEITInventory.Text = "CEIT Inventory"

$label2.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 174
$System_Drawing_Point.Y = 87
$label2.Location = $System_Drawing_Point
$label2.Name = "label2"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 12
$System_Drawing_Size.Width = 134
$label2.Size = $System_Drawing_Size
$label2.TabIndex = 7
$label2.Text = "Enter prefix IE. CEIT255"
$label2.add_Click($handler_label3_Click)

$CEITInventory.Controls.Add($label2)


$SearchBox.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 175
$System_Drawing_Point.Y = 102
$SearchBox.Location = $System_Drawing_Point
$SearchBox.Name = "SearchBox"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 147
$SearchBox.Size = $System_Drawing_Size
$SearchBox.TabIndex = 4
$SearchBox.add_Click 

$CEITInventory.Controls.Add($SearchBox)


$SearchButton.DataBindings.DefaultDataSourceUpdateMode = 0


$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 209
$System_Drawing_Point.Y = 131
$SearchButton.Location = $System_Drawing_Point
$SearchButton.Name = "SearchButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$SearchButton.Size = $System_Drawing_Size
$SearchButton.TabIndex = 3
$SearchButton.Text = "Search"
$SearchButton.UseVisualStyleBackColor = $False
$SearchButton.add_Click($SearchButton_OnClick)


$CEITInventory.Controls.Add($SearchButton)

$label1.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 11
$System_Drawing_Point.Y = 88
$label1.Location = $System_Drawing_Point
$label1.Name = "label1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 17
$System_Drawing_Size.Width = 157
$label1.Size = $System_Drawing_Size
$label1.TabIndex = 2
$label1.Text = "Enter Single Machine Name"
$label1.add_Click($handler_label1_Click)

$CEITInventory.Controls.Add($label1)

$textbox1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 102
$textbox1.Location = $System_Drawing_Point
$textbox1.Name = "textbox1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 137
$textbox1.Size = $System_Drawing_Size
$textbox1.TabIndex = 1
#$textbox1.add_TextChanged($handler_textBox1_TextChanged)

$CEITInventory.Controls.Add($textBox1)


$OKbutton1.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 39
$System_Drawing_Point.Y = 131
$OKbutton1.Location = $System_Drawing_Point
$System_Windows_Forms_Padding = New-Object System.Windows.Forms.Padding
$OKbutton1.Margin = $System_Windows_Forms_Padding
$OKbutton1.Name = "OKbutton1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$OKbutton1.Size = $System_Drawing_Size
$OKbutton1.TabIndex = 3
$OKbutton1.Text = "Ok"
$OKbutton1.UseVisualStyleBackColor = $False
$OKbutton1.add_Click($OKbutton1_OnClick)

$CEITInventory.Controls.Add($OKbutton1)



#Save  state of the form
$InitialFormWindowState = $CEITInventory.WindowState
#Init the OnLoad event to correct the initial state of the form
$CEITInventory.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$CEITInventory.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm