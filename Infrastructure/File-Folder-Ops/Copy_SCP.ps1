<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 3/9/2018
    Organization: Domain, Inc.
    Filename: Copy_SCP.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Functions

function Select-file
{
    Add-Type -AssemblyName System.Windows.Forms
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Multiselect = $false # Multiple files can be chosen
        #Filter = 'Images (*.jpg, *.png)|*.jpg;*.png' # Specified file types
    }
    
    [void]$FileBrowser.ShowDialog()

    $file = $FileBrowser.FileName;

    <#
    If($FileBrowser.FileNames -like "*\*") {

        # Do something 
        $FileBrowser.FileName #Lists selected files (optional)
        
    }

    else {
        Write-Host "Cancelled by user"
    }
    #>
    return $file
}

function Putty-Check
{
    if ((Test-Path "C:\Program Files (x86)\PuTTY\pscp.exe") -eq $true)
    {
        $version = "x86"
    }
    elseif ((Test-Path "C:\Program Files\PuTTY\pscp.exe") -eq $true)
    {
        $version = "x64"
    }
    else 
    {
        $version = $null
    }
    return $version
}

function Upload-File ($version, $selectedfile)
{
    if ($version -eq "x86")
    {
        #start-process -FilePath "C:\Program Files (x86)\PuTTY\pscp.exe" -ArgumentList "$selectedfile sortiz@0.0.0.0:/home/sortiz/"
        & "C:\Program Files (x86)\PuTTY\pscp.exe" $selectedfile "sortiz@0.0.0.0:/home/sortiz/"
    }
}

# ----------------------------------------------------------------------------------------------
# Variables

$selectedfile = Select-file
$version = Putty-Check

# ----------------------------------------------------------------------------------------------
# Script

if ($version -eq "x86")
{
    start-process -FilePath "C:\Program Files (x86)\PuTTY\pscp.exe" -ArgumentList "-pw <password> $selectedfile sortiz@0.0.0.0:/home/sortiz/"
}
elseif ($version -eq "x64")
{
    start-process -FilePath "C:\Program Files\PuTTY\pscp.exe" -ArgumentList "-pw <password> $selectedfile sortiz@0.0.0.0:/home/sortiz/"
}
else 
{
    Write-host "PuTTY not detected/installed on system.  Please verify that PuTTY is installed."
}