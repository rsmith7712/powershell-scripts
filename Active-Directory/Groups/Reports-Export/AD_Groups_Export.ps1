# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    AD_Groups_Export.ps1

.DESCRIPTION
    Exports all Active Directory groups in the domain to a date-stamped CSV.

.FUNCTIONALITY
    Exports AD groups to a dated CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#// Start of script
#// Get year and month for csv export file
$DateTime = Get-Date -f "yyyy-MM"

#// Set CSV file name
$CSVFile = "C:\AD_Groups"+$DateTime+".csv"

#// Create emy array for CSV data
$CSVOutput = @()

#// Get all AD groups in the domain
$ADGroups = Get-ADGroup -Filter *

#// Set progress bar variables
$i=0
$tot = $ADGroups.count

foreach ($ADGroup in $ADGroups) {
	#// Set up progress bar
	$i++
	$status = "{0:N0}" -f ($i / $tot * 100)
	Write-Progress -Activity "Exporting AD Groups" -status "Processing Group $i of $tot : $status% Completed" -PercentComplete ($i / $tot * 100)

	#// Ensure Members variable is empty
	$Members = ""

	#// Get group members which are also groups and add to string
	$MembersArr = Get-ADGroup -filter {Name -eq $ADGroup.Name} | Get-ADGroupMember | select Name
	if ($MembersArr) {
		foreach ($Member in $MembersArr) {
			$Members = $Members + "," + $Member.Name
		}
		$Members = $Members.Substring(1,($Members.Length) -1)
	}

	#// Set up hash table and add values
	$HashTab = $NULL
	$HashTab = [ordered]@{
		"Name" = $ADGroup.Name
		"Category" = $ADGroup.GroupCategory
		"Scope" = $ADGroup.GroupScope
		"Members" = $Members
	}

	#// Add hash table to CSV data array
	$CSVOutput += New-Object PSObject -Property $HashTab
}

#// Export to CSV files
$CSVOutput | Sort-Object Name | Export-Csv $CSVFile -NoTypeInformation

#// End of script