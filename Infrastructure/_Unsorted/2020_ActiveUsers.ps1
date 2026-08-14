# LEGAL
<# LICENSE
    MIT License, Copyright 2020 Richard Smith

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
.Name
    ActiveUsers.ps1

.DESCRIPTION
    -Query AD Computers for their Name, IP Address, MAC Address, Operating System,
    and Service Pack information.
    -Output results to a text file on the local system.

.FUNCTIONALITY
  1. Use PowerShell and the AD module to query AD Computers for their Name,
    IP Address, MAC Address, Operating System, and Service Pack information.
  2. Output results to a text file on the local system.

.URL
    See location for notes and history:
    https://github.com/admin7712
        PowerShell Scripts

    Author:
    Original: Kevin Mangus
    Modified: Richard Smith
 
    ByteConversion: https://stackoverflow.com/a/24617034
    Test Dir - C:\Users\Guest\Documents
#>

#/// BASICS ///

#--Input Flags
param (
    [switch]$gs = $false, # Input for getting size of a directory
    [switch ]$d = $false,  # Input for specific directory :: default is \\srv\S$\...\UserHomeDirs$
    [switch]$p = $false   # To purge directories that haven't been accessed and written to within a year 
)

#--Variables
$current_user = "C:\Users\$($env:UserName)\Documents"
$obj = New-Object -Type psobject
$dir_count = 1

#--Close CSV file if open
#$excel = [System.Runtime.InteropServices.Marshal]::GetActiveObject("Excel.Application")
#$excel.DisplayAlerts = $false
#$excel.Workbooks | ForEach-Object{if($_.Name -imatch "results.csv"){$_.Close()}}

#--Pre-CleanUp
Remove-Item $current_user\results.csv -ErrorAction Ignore #Main Output
#//////////////

#/// Functions ///
Function Get-Size ($Folder){
    $bytecount =  (Get-ChildItem $Folder -Recurse -File -ErrorAction Ignore | Measure-Object -Property Length -Sum -ErrorAction Ignore).Sum

    #--Byte Conversion 
    switch -Regex ([math]::Truncate([math]::log($bytecount,1024))) {
        '^0' { $script:size = "$bytecount Bytes"}
        '^1' { $script:size = "{0:n2} KB" -f ($bytecount / 1KB) }
        '^2' { $script:size = "{0:n2} MB" -f ($bytecount / 1MB) }
        '^3' { $script:size = "{0:n2} GB" -f ($bytecount / 1GB) }
        '^4' { $script:size = "{0:n2} TB" -f ($bytecount / 1TB) }
        Default { $script:size = "{0:n2} KB" -f ($bytecount / 1KB)} #can change this to pb if need arises
    }
}

Function TakeFolder ($foldername) {
    takeown.exe /f $foldername /A /R /D y | Out-Null
    icacls.exe $foldername /grant 'DOMAIN_2000\Domain Admins:(F)' /C /T /Q
}
#//////////////

#/// Main Code ///
#--Flag Check for Directory
if($d){
    $target_dir = Get-ChildItem "$(Read-Host "Input Path to Directory")" | ForEach-Object { $_.FullName }
} else {
    $target_dir = Get-ChildItem "\\SERVER\SHARE\...\UserHomeDirs$" | ForEach-Object { $_.FullName}
}

#--Needed for % bar
$complete_dir_count = ($target_dir | Measure-Object).Count

#Access Information of Files :: $folder returns file path
foreach($folder in $target_dir){

    #--Percentage Bar
    $pcomplete = ($dir_count / $complete_dir_count) * 100
    Write-Progress -Activity "Scanning Directory for Information" -Status "Working on directory $folder" -PercentComplete $pcomplete
   
    #--Grabbing Folder Owner
    $Folder_Owner = @((Get-Acl $folder).Access |
                        Select-Object -Unique -ExpandProperty IdentityReference |
                        ForEach-Object { $_.toString().Split('\')[1] } |
                        ForEach-Object { ($_ -replace("SYSTEM|Users|Administrators|Domain Admins", "")).ToLower()} |
                        Where-Object { $_.Trim(" ")}
                    )
 
    #--Grabbing Other Folder Information
    $Folder_Name = Get-Item $folder| Select-Object Name | ForEach-Object { $_.psobject.toString().Split('=')[1] | ForEach-Object { $_.trimEnd('}') }}
    $Last_Accessed = Get-Item $folder | Select-Object LastAccessTime | ForEach-Object { $_.psobject.toString().Split('=')[1] | ForEach-Object { $_.trimEnd('}') }}
    $Last_Write = Get-Item $folder | Select-Object LastWriteTime | ForEach-Object { $_.psobject.toString().Split('=')[1] | ForEach-Object { $_.trimEnd('}') }}

    #--Adding Items to custom object
    $obj | Add-Member -Name 'Folder_Name' -Type NoteProperty -Value $Folder_Name -Force
    $obj | Add-Member -Name 'User' -Type NoteProperty -Value ($Folder_Owner -join ', ') -Force
    $obj | Add-Member -Name 'Last_Accessed' -Type NoteProperty -Value $Last_Accessed -Force
    $obj | Add-Member -Name 'Last_Written' -Type NoteProperty -Value $Last_Write -Force

    #--Get-Size Flag Handling
    if($gs){ 
        Get-Size $folder
        $obj | Add-Member -Name 'Size' -Type NoteProperty -Value $size -Force
    }

    #--Purge Flag
    if($p){  
        if ($Folder_Owner[0] -eq $NULL ){ #folders without users typically means they aren't in AD
            if( (Get-Date).AddYears(-1) -gt $Last_Accessed){ #If folder hasn't been accessed&written within a year from current date
                if( (Get-Date).AddYears(-1) -gt $Last_Write){
                    #Removing Items 
                    try {
                        Remove-Item -path $folder -recurse -Force -ErrorAction Stop
                    } catch {
                        TakeFolder $folder
                        try {
                            Remove-Item -path $folder -recurse -Force -ErrorAction Stop
                        } catch {
                            $ErrorMessage = $_.Exception.Message
                            $FailedItem = $_.Exception.ItemName
                            Write-Output "Error Message: $ErrorMessage `r `n Failed Item: $FailedItem" | Out-File -Append  $current_user\remove_item_erros.txt
                        }                 
                    }      
                }
            } 
        } # END of NULL check

        if ( -not(Test-Path $folder)){ #item is purged and fits parameters
            $obj | Add-Member -Name 'Folders_Purged' -Type NoteProperty -Value "Purged" -Force
        }
        else { #item isn't purged and doesn't fit parameters
            $obj | Add-Member -Name 'Folders_Purged' -Type NoteProperty -Value "" -Force
        }

    } # End of P flag

    #--Export Custom object to csv
    $obj |Export-Csv -path $current_user\results.csv -Append -NoTypeInformation
    $dir_count++

} #End_of_Loop