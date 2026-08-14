# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Move and disable inactive computer accounts.ps1

.DESCRIPTION
    Finds inactive Active Directory computer accounts and moves them to a designated OU and disables them (uses Quest ActiveRoles cmdlets).

.FUNCTIONALITY
    Moves and disables inactive computer accounts.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Script used to fiund all accounts ahwihc are inactive in Active Directory and move them to a specific OU and disable them
#Customise the script with the source serach OU and desitnation OU to move the accounts, and specify the number of days the computer
#must have been inactive for - suggested value is 60 days. 

#Script uses quest powershell commandlets which can be downloaded for free from quest website
# http://www.quest.com/powershell/activeroles-server.aspx

#Specify the OU you want to search for inactive accounts

	$SearchOU=“ou=AllComputers,DC=Domain,DC=Com"

#Specify the OU you want to move your inactive computer accounts to

	$DestinationOU=“ou=DisabledComputers,DC=Domain,DC=Com"

#Specify the number of days that computers have been inactive for

	$NumOfDaysInactiveFor = 60
	
#Specify the description to set on the computer account

	$Today = Get-Date
	
	$Description = "Account disabled due to inactivity on $Today"

#DO NOT MODIFY BELOW THIS LINE

Get-QADComputer -InactiveFor $NumOfDaysInactiveFor -SizeLimit 0 -SearchRoot $searchOU -IncludedProperties ParentContainerDN | foreach { 

	$computer = $_.ComputerName
	$SourceOU = $_.DN
	
	#Remove the commented # from the next line if you want to set the description to be the source OU
	#$Description = "SourceOU was $SourceOu"
	
	Set-QADComputer $computer -Description $Description

	Disable-QADComputer $computer

	Move-QADObject $computer -NewParentContainer $destinationOU 
	


}