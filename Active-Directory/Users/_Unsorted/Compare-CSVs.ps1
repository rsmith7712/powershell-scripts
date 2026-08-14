# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Compare-CSVs.ps1

.SYNOPSIS
  Matches users in two csvs
 
.DESCRIPTION
  Compares a dump of MyHR and AD to try and match users. Requires parameters, see next line.

.EXAMPLE
  Compare-CSVs.ps1 -HRexport .\MyHR_Export.csv -ADexport .\AD_Export.csv -ExportPath .\Merged_Data.csv
  Compare-CSVs.ps1 .\MyHR_Export.csv .\AD_Export.csv .\Merged_Data.csv
  
.NOTES
  Version:        1.1
  Author:         user26
  Creation Date:  03/14/2017
  Purpose/Change: Added parameters. Combined searches to increase speed. Added AD No Match.
            Still needs logging and better error handling.

.HISTORY
  Version:        1.0
  Author:         user26
  Creation Date:  03/06/2017
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Compares a dump of MyHR and AD to try and match users. Requires parameters, see next line.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$HRexport,
    
    [Parameter(Mandatory=$True,Position=2)]
    [string]$ADexport,

    [Parameter(Mandatory=$True,Position=3)]
    [string]$ExportPath
    )
$VerbosePreference = "Continue" #Set to SilentlyContinue for Production use.
$ErrorActionPreference = "SilentlyContinue"
$TempPath = "C:\Temp\"

Function Merge-CSVFiles($CSVPath,$XLOutput)
{
	$csvFiles = Get-ChildItem ("$CSVPath\*") -Include *.csv
	$Excel = New-Object -ComObject excel.application
	$Excel.visible = $false
	$Excel.sheetsInNewWorkbook = $csvFiles.Count
	$workbooks = $excel.Workbooks.Add()
	$CSVSheet = 1

	Foreach ($CSV in $Csvfiles)
	{
		If ($Script:ConResult -eq 0)
		{
			Convert-IDtoUser $CSV.name
		}
		$worksheets = $workbooks.worksheets
		$CSVFullPath = $CSV.FullName
		$SheetName = ($CSV.name -split "\.")[0]
		$worksheet = $worksheets.Item($CSVSheet)
		$worksheet.Name = $SheetName
		$TxtConnector = ("TEXT;" + $CSVFullPath)
		$CellRef = $worksheet.Range("A1")
		$Connector = $worksheet.QueryTables.add($TxtConnector, $CellRef)
		$worksheet.QueryTables.item($Connector.name).TextFileCommaDelimiter = $True
		$worksheet.QueryTables.item($Connector.name).TextFileParseType = 1
		$worksheet.QueryTables.item($Connector.name).Refresh()
		$worksheet.QueryTables.item($Connector.name).delete()
		$worksheet.UsedRange.EntireColumn.AutoFit()
		$CSVSheet++
	}
	$workbooks.SaveAs($XLOutput, 51)
	$workbooks.Saved = $true
	$workbooks.Close()
	[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbooks) | Out-Null
	$excel.Quit()
	[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
	[System.GC]::Collect()
	[System.GC]::WaitForPendingFinalizers()
}

$HeaderRow = "EmployeeID,FirstName,LastName,SamAccountName,MatchType"
$FullMatchExport = @()
$FullMatchExport += $HeaderRow
$PartialMatchExport = @()
$PartialMatchExport += $HeaderRow
$NoMatchExport = @()
$NoMatchExport += $HeaderRow

$titles = @("Mr.","Mr","Mrs.","Mrs","Ms.","Ms")
$ADdata = Import-CSV $ADexport
$names = Import-Csv $HRexport | Select-Object -Property FIRST_NAME,LAST_NAME,EMPLOYEE_ID
If(!($?))
{
    Write-Host "Please verify the CSVs provided in the Parameters are correct. Unknown CSV detected."
    Write-Host "Script will exit in 30 seconds."
    Start-Sleep 30
    Exit 5
}

foreach($name in $names)
{
    Write-Verbose $name
    $first = $name.FIRST_NAME
    If($titles -contains $first) # Ignores titles
    {
        $first = $first[1]
    }
    Else
    {
        #Don't change first name
    }
    $last = $name.LAST_NAME
    $FirstTwo = $first.substring(0,2)
    $fullname = $name.FULL_NAME
    
    $Found = $Null
    Foreach($user in $ADdata)
    {
        If($fullname -match $user.FullName)
        {
            If($user.EmployeeID -ne $Null)
            {
                $user.EmployeeID += "-$name.EMPLOYEE_ID"
                $user.MatchType = "Multiple"
                $PartialMatchExport += "$name.EMPLOYEE_ID,$user.FirstName,$user.LastName,$user.SamAccountName,Multiple"
            }
            Else
            {
                $user.EmployeeID = $name.EMPLOYEE_ID
                $user.MatchType = "FullName"
                $FullMatchExport += "$name.EMPLOYEE_ID,$user.FirstName,$user.LastName,$user.SamAccountName,FullName"
                Write-Verbose $fullname,$user.EmployeeID
            }
        }
        ElseIf($Last -match $user.LastName)
        {
            If($user.EmployeeID -ne $Null)
            {
                $user.EmployeeID += "-$name.EMPLOYEE_ID"
                $user.MatchType = "Multiple"
                $PartialMatchExport += "$name.EMPLOYEE_ID,$user.FirstName,$user.LastName,$user.SamAccountName,Multiple"
            }
            ElseIf($FirstTwo -match $user.FirstName.substring(0,2))
            {
                $user.EmployeeID = $name.EMPLOYEE_ID
                $user.MatchType = "Partial"
                Write-Verbose $fullname,$user.EmployeeID
                $PartialMatchExport += "$name.EMPLOYEE_ID,$user.FirstName,$user.LastName,$user.SamAccountName,Partial"
            }
            Else
            {
                $user.MatchType = "NoADMatch"
                $NoMatchExport += ",$user.FirstName,$user.LastName,$user.SamAccountName,NoADMatch"
            }
        }
        Else
        {
            $user.MatchType = "NoADMatch"
            $NoMatchExport += ",$user.FirstName,$user.LastName,$user.SamAccountName,NoADMatch"
        }
    }
    #$fullname | Out-File C:\temp\hr_names.csv -Append
}

$FullMatchExport | Export-CSV -Path "$TempPath\FullMatchExport.csv" -NoTypeInformation
$PartialMatchExport | Export-CSV -Path "$TempPath\PartialMatchExport.csv" -NoTypeInformation
$NoMatchExport | Export-CSV -Path "$TempPath\NoMatchExport.csv" -NoTypeInformation

Merge-CSVFiles $TempPath $ExportPath
#$ADdata | Export-CSV -path $ExportPath -NoTypeInformation