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
    010-CreateDrives_3_2.ps1

.DESCRIPTION
    Brings disks online, initializes, partitions and formats them, and reletters the CD-ROM drive (server drive provisioning; variant).

.FUNCTIONALITY
    Initializes, partitions and formats server disks.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


Function ReLetterCD ($oldletter, $newletter) {
    #This function will change the CD-ROM
    Get-WmiObject -Class Win32_volume -Filter "DriveLetter = '$oldletter'" |Set-WmiInstance -Arguments @{DriveLetter=$newletter}
}
Function BringUpDisk ($disknum, $partstyle) {
    # This function brings disk online and sets them to read/write
    Set-Disk $disknum -isOffline $false
    Set-Disk $disknum -IsReadOnly $false
    Initialize-Disk $disknum -PartitionStyle $partstyle
}
Function PartitionFormat ($disknum, $driveletter, $fstype, $fslabel) {
    #This function creates a partition on an attached disk and then formats it
    New-Partition -DiskNumber $disknum -UseMaximumSize -IsActive -DriveLetter $driveletter | Format-Volume -FileSystem $fstype -NewFileSystemLabel $fslabel
}
Function LabelVolume ($driveletter, $fslabel) {
    #This function will alter the label of an existing volume as needed
    Set-Volume -DriveLetter $driveletter -NewFileSystemLabel $fslabel
}
Function CreateAdminFolder ($driveletter) {
    #This function creates a folder called 'Admin' to store temporary and install related files
    New-Item "$driveletter\Admin" -type directory
    New-Item "$driveletter\Admin\-For Temp Use Only!  Files can be deleted at any time!" -type file
}

<#
Function SetPagefile {
    #This function relocates the Windows Pagefile on to drive D:
    #This function is not yet working; it needs to remain commented out until it is
    [Int] $basesize = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | Foreach {"{0:N2}" -f ([math]::round(($_.Sum / 1GB),2))}
    [Int] $basesize = $basesize * 1024
    [Int] $maxsize = $basesize * 1.5
    #$computersys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
    #$computersys.AutomaticManagedPagefile = $False
    #$computersys.Put()
    $pagefile = Get-WmiObject -Query "Select * From Win32_PageFileSetting Where Name='c:\\pagefile.sys'"
    $pagefile
    #$pagefile.Delete()
    #Set-WMIInstance -class Win32_PageFileSetting -Arguments @{name="d:\pagefile.sys";InitialSize = $basesize;MaximumSize = $maxsize}
    #$computersys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
    #$computersys.AutomaticManagedPagefile = $True
    #$computersys.Put()
    New-Item D:\"-Place no files in this directory!!-" -type file
    New-Item D:\"-Hidden system pagefile lives here and needs all available space!-" -type file
}
#>

# Main Body
ReLetterCD "D:" "F:"
BringUpDisk 1 "MBR"
BringUpDisk 2 "MBR"
PartitionFormat 1 "D" "NTFS" #"PAGEFILE"
PartitionFormat 2 "E" "NTFS" #"APPLICATION"
LabelVolume "C" "SYSTEM"
LabelVolume "D" "PAGEFILE"
LabelVolume "E" "APPLICATION"
#SetPagefile
CreateAdminFolder "E:"

#Ends 0.0.0.0 -AddressFamily IPv4 -PrefixLength 8