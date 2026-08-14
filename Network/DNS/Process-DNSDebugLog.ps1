# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    Process-DNSDebugLog.ps1

  .SYNOPSIS
  Name: Process-DNSDebugLog.ps1
  Version: 1.0
  Author: Russell Tomkins - Microsoft Premier Field Engineer
  Blog: https://aka.ms/russellt

  Source: https://www.github.com/russelltomkins/Active-Directory

  .DESCRIPTION
  Converts a DNS Debug log into a .CSV file. Only processes 'PACKET' lines and
  skips a few fields.
    
  .EXAMPLE
  Converts and appends the specified input DNSDebuglog file into a CSV called DNSDebugLog.csv
  .\Process-DNSDebugLog.ps1 -InputFile <dnsdebuglog.txt>
  .\Process-DNSDebugLog.ps1 -InputFile .\DNSDebugLog.txt
  
.EXAMPLE
  Converts and appends the specified input DNSDebuglog file into the CSV file provided
  .\Process-DNSDebugLog.ps1 -InputFile <path-to-dnsdebuglog.txt> -OutputFIle <path-to-output.csv>
  .\Process-DNSDebugLog.ps1 -InputFile .\DNSDebugLog.txt -OutputFile C:\Temp\DNS-Server1.csv
  
  .PARAMETER InputFile
  The file path to DNS debug log input file to read from.

  .PARAMETER OutputFile
  The file path to the CSV output file to append to  

  LEGAL DISCLAIMER
  This Sample Code is provided for the purpose of illustration only and is not
  intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
  RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
  EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
  MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
  nonexclusive, royalty-free right to use and modify the Sample Code and to
  reproduce and distribute the object code form of the Sample Code, provided
  that You agree: (i) to not use Our name, logo, or trademarks to market Your
  software product in which the Sample Code is embedded; (ii) to include a valid
  copyright notice on Your software product in which the Sample Code is embedded;
  and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
  against any claims or lawsuits, including attorneys fees, that arise or result
  from the use or distribution of the Sample Code.
   
  This posting is provided "AS IS" with no warranties, and confers no rights. Use
  of included script samples are subject to the terms specified
  at http://www.microsoft.com/info/cpyright.htm.

.FUNCTIONALITY
    Converts a DNS Debug log into a .CSV file. Only processes 'PACKET' lines and
      skips a few fields.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# -----------------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------------
[CmdletBinding()]
    Param (
    [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][String]$InputFile,
    [Parameter(Mandatory=$False)][String]$OutputFile=".\DNSDebugLog.csv")
    
# Grab the full file name and set the Split options
$InputFile = (Get-Item $InputFile).FullName
If(-Not(Test-Path $OutputFile)){New-Item $OutputFile | Out-Null}
$OutputFile = (Get-Item $OutputFile).FullName
$Option = [System.StringSplitOptions]::RemoveEmptyEntries

# Loop through the input file, one line at a time.
ForEach ($Line in [System.IO.File]::ReadLines("$InputFile")) {

	# Create the custom PSObject
	$Row = "" | Select Date,Time,Protocol,Direction,RemoteIP,OpCode,QuestionType,QuestionName

	# Ignore the extra lines and any entry that isn't related to a PACKET
	If($Line -cmatch ' PACKET '){
		$Part1 = $Line.Split(' ',5,$Option)
		$Part2 = $Part1[4].Split(' ',4,$Option)
		$Part3 = $Part2[3].Split(' ',4,$Option) 
		$Part4 = $Part3[3].Split(']',2,$Option).Trim()	# We ignore the data in this section.
		$Part5 = $Part4[1].Split(' ',$Option)
	
        # Populate the custom object
    	$Row.Date = $Part1[0]
		$Row.Time = $Part1[1]
		$Row.Protocol = $Part2[1]
		$Row.Direction = $Part2[2]
		$Row.RemoteIP = $Part3[0]
		$Row.OpCode = $Part3[2]
		$Row.QuestionType = $Part5[0]
		$Row.QuestionName = $Part5[1]

		# Convert the questin name to a FQDN
 		[System.Collections.ArrayList]$arrQuestionName = $Row.QuestionName.Split('()',$Option)  # Create a list object
		$Count = ($arrquestionName.Count-1)/2                                                   # Figure out how many lines to remove
		For($i=0;$I -le $Count;$I++){$arrQuestionName.RemoveAt($i)}                             # Loop through and remove each extra line
		$Row.QuestionName = $arrQuestionName -join '.'
	
        # Append the row to our Output
    	$Row | Export-CSV -NoTypeInformation -Append $OutputFile
	} # End If Statement
} # Next Line
# -----------------------------------------------------------------------------
# End of Script
# -----------------------------------------------------------------------------
