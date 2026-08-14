<#
.PURPOSE
    PowerShell script to query file versions on remote computers

.NAME
    Get-FileVersionInfoRemotely.ps1
    
.FEATURES
    1. It takes one or more computer names as input.

    2. It takes the local path of the file that you want to query. 
    For example, if you want to query the file version of 
    c:\program files\app1\appinfo.dll, you can provide the 
    file path as is rather than specify an UNC path such 
    as \\computername\c$\program files\app1\appinfo.dll.

    3. It provides the status of each computer in the report. 
    The value of this status column indicates the result of 
    querying that computer. See the output screenshot at the 
    end of this article to understand this better.
        * SUCCESS: Indicates that the script was able to 
        query the file version on a remote computer.

        * FailedTOQuery: Indicates that script was unable to 
        query the file version. Possible reasons include file 
        permissions or trouble accessing the remote $ share of 
        the drive where the file resides.

        * PathNotAccessable: Indicates that the script was unable 
        to access the path. As a result, the file was not found 
        in the location that was provided in the input.

        * NotReachable: Indicates that the computer you want to 
        query did not respond to the ping.

    4. It generates a CSV output that you can easily filter using 
    Excel and use for further processing.

    5. Along with the file version, the script gives the product 
    version, original name of the file, product name, and file 
    description.

    6. You can pass the output file name to the -OutputFile

.EXAMPLE
    - Query the file version of a remote computer named srv. 
    The -OutputFile parameter is optional. If you don’t specify it, 
    the script writes the output to c:\temp\fileversioninfo.csv by 
    default:
    PS C:\temp> .\Get-FileVersionInfoRemotely.ps1 -ComputerName srv -Path C:\Windows\system32\tcpipcfg.dll -OutputFile c:\temp\fileversiondetails.csv

.EXAMPLE
    - You can use the above command to collect file version 
    information from multiple computers as well. To do so, provide 
    a list of computer names as comma-separated values to 
    the -ComputerName parameter, as shown below:
    PS C:\temp> .\Get-FileVersionInfoRemotely.ps1 -ComputerName srv,srv -Path C:\Windows\system32\tcpipcfg.dll -OutputFile c:\temp\fileversiondetails.csv

.EXAMPLE
    - For a large number of computers, place the computer names 
    in a text file by entering one computer name per line. You 
    can then pass the text file to the script, as shown below:
    PS C:\temp> .\Get-FileVersionInfoRemotely.ps1 -ComputerName (get-content c:\temp\workstations.txt) -Path C:\Windows\system32\tcpipcfg.dll -OutputFile c:\temp\fileversiondetails.csv

    - You can place the text file anywhere, but make sure to 
    provide the complete file path. No restriction exists with 
    regard to the name of the text file.


.HISTORY
    Author      Venkat Sri (Creator)
    Mod         Richard Smith, user10

.RESOURCES
- https://4sysops.com/archives/powershell-script-to-query-file-versions-on-remote-computers/


#>


[CmdletBinding()]
Param(
	[string[]]$ComputerName = $env:ComputerName,
	[Parameter(mandatory=$true)]
	[string]$Path,
	[string]$OutputFile = "c:\temp\FileVersionInfo.csv"
)

$parts = $Path -split ":\\"
$DriveLetter = $parts[0]
$PathwoRoot = $parts[1]
Write-Verbose "Drive letter is $DriveLetter"
Write-Verbose "Remaining Path is $PathwoRoot"
try {
	$Parent = [System.IO.Directory]::GetParent($OutputFile)
	if(Test-Path $Parent.FullName) {
		Write-Verbose "Output folder $($parent.FullName) exists"
	} else {
		throw "Directory $($parent.FullName) not found. Output file cannot be created"
	}
} catch {
	Write-Error "Error occurred while checking output folder. $_"
	return
}
$OutputArr = @()
foreach($Computer in $ComputerName) {
	Write-Host "Querying file version on $Computer"
	$OutputObj = New-Object -TypeName PSobject  
	$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer 
	$OutputObj | Add-Member -MemberType NoteProperty -Name FilePath -Value $Path
	$OutputObj | Add-Member -MemberType NoteProperty -Name FileVersion -Value $null
	$OutputObj | Add-Member -MemberType NoteProperty -Name ProductVersion -Value $null
	$OutputObj | Add-Member -MemberType NoteProperty -Name Status -Value $null
	$OutputObj | Add-Member -MemberType NoteProperty -Name OriginalName -Value $null
	$OutputObj | Add-Member -MemberType NoteProperty -Name FileDescription -Value $null
    $OutputObj | Add-Member -MemberType NoteProperty -Name ProductName -Value $null
    $OutputObj | Add-Member -MemberType NoteProperty -Name LastModifiedTime -Value $null #S wapnil Kamnli
	
	if(Test-Connection -ComputerName $Computer -count 1 -quiet) {
		$TargetPath = [string]::format("\\{0}\{1}`$\{2}",$Computer,$DriveLetter,$PathwoRoot)
		Write-verbose "Trying to get $TargetPath file version"
		if(Test-Path $TargetPath) {
			try {
                $VersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($TargetPath)
                # Returns build version and current patch version info of file - Swapnil Kambli
                $OutputObj.FileVersion = ("{0}.{1}.{2}.{3}" -f $VersionInfo.FileMajorPart,$VersionInfo.FileMinorPart, $VersionInfo.FileBuildPart, $VersionInfo.FilePrivatePart)
                # Returns build version of file
				#$OutputObj.FileVersion = $VersionInfo.FileVersion
				$OutputObj.ProductVersion = $VersionInfo.ProductVersion
				$OutputObj.OriginalName = $VersionInfo.OriginalName
				$OutputObj.FileDescription = $VersionInfo.FileDescription
                $OutputObj.ProductName = $VersionInfo.ProductName
                $OutputObj.LastModifiedTime = (get-item $TargetPath).LastWriteTime # Swapnil Kamnli
				$OutputObj.Status = "SUCCESS"
			} catch {
				$OutputObj.Status = "FailedTOQuery"
			}
		} else {
				$OutputObj.Status = "PathNotAccessable"
		}
	} else {
		$OutputObj.Status = "NotReachable"
	}
	$OutputArr += $OutputObj
	Write-Verbose $OutputObj
}

$OutputArr | Export-csv $OutputFile -NotypeInformation








