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
    fAdd-CsvToExcelSheet.ps1

.DESCRIPTION
    Merges a folder of CSV files into a single multi-worksheet Excel workbook using the Excel COM object.

.FUNCTIONALITY
    Combines multiple CSVs into one Excel workbook.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

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
}#=======================================[ End Function ]==========================================
Merge-CSVFiles -CSVPath "\\SERVER\SHARE\...\csv" -XLOutput "\\SERVER\SHARE\...\DLMembers.xlsx"