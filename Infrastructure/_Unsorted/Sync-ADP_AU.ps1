# LEGAL
<# LICENSE
    MIT License, Copyright 2019 Richard Smith

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
    Sync-ADP_AU.ps1

.SYNOPSIS
  Sync-ADP_AU.ps1
 
.DESCRIPTION
 Sync-ADP_AU.ps1 copies employee data out of ADP Australia and provides it to the Cornerstone training application for tracking.

 * Must have the correct PGP and SSH certificates installed on the computer from which this script is executed.
 * Requires WinSCP, gpg.exe, and the GnuPg PowerShell module to function correctly.

    https://www.gpg4win.org/
    https://winscp.net/eng/download.php
    https://winscp.net/eng/docs/library_examples
    https://4sysops.com/archives/encrypt-and-decrypt-files-with-powershell-and-pgp/

.EXAMPLE
  
.NOTES
  Version:        1.2
  Author:         user10
  Modified Date:  02/27/2019
  Purpose/Change: Added Add-TxtFiles function to create additional .txt files based on .csv file names
                  to be uploaded to Cornerstone SFTP production site.  Change requested by user21.

.HISTORY
  Version:        1.1
  Author:         user10(02/19/2019)
  Purpose/Change: Updated Cornerstone SFTP path to the production URL. Change requested by user21.

  Version:        1.0
  Author:         user10 (07/10/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Sync-ADP_AU.ps1 copies employee data out of ADP Australia and provides it to the Cornerstone training application for tracking.

     * Must have the correct PGP and SSH certificates installed on the computer from which this script is executed.
     * Requires WinSCP, gpg.exe, and the GnuPg PowerShell module to function correctly.

        https://www.gpg4win.org/
        https://winscp.net/eng/download.php
        https://winscp.net/eng/docs/library_examples
        https://4sysops.com/archives/encrypt-and-decrypt-files-with-powershell-and-pgp/

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "Sync-ADP_AU" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.

# Functions
#################################
Function Log_ToSplunk{
Param(
    [parameter(Mandatory=$true,
    Position=0)]
    [String]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    [String]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    [String]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
    [int]
    $ID = $Null
)

$product = "team_" + $Script:ProductName
$uri = "https://hecext.example.com:18443/services/collector/event"
$header = @{}
$header.add('Content-Type', 'application/json')
$header.add('Authorization', 'Splunk Application-Key-Here')
$body = @{
    sourcetype = 'domain:ps:log'
    host = $env:COMPUTERNAME
    event = @{
        message = $Message
        user = $env:USERNAME
        product = $Product
        type = $Type
        status = $Status
        id = $ID
    }
}
$body = $body | ConvertTo-Json
Invoke-WebRequest -Uri $uri -Method Post -Headers $header -Body $body | Out-Null
}
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Send_Failure_Email($body){
   $smtp = "smtpi.example.com"
   $to = "a-team@example.com","applications@example.com","lms@example.com"
   $from = "Domain Automation <donotreply@example.com>"
   $subject = "ADP Australia - Cornerstone SFTP File Transfer Error"                                                        
   Send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body
   }

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Function Purge-Files{
Param(
    [parameter(Mandatory=$false)]
    [String]
    $days = 7
    )

$archive = (Get-ChildItem "C:\temp\ADP_AU-SFTP\archive")
    Try 
    {
    foreach($file in $archive){
        $age = ((Get-Date) - $file.LastWriteTime).Days
        if ($age -gt $days -and $file.PsISContainer -ne $True){
            $file.Delete()
            }
        }
        $output = "Clean-up for files older that 7 days succeeded."
        Write-Host $output -ForegroundColor Green
        Log_ToSplunk -Message $output
        Exit 0
    }

    Catch
    {
        $output = "Clean-up for files older that 7 days failed."
        Write-Host $output -ForegroundColor Red
        Log_ToSplunk -Message $output -Status "Fail"
        Send_Failure_Email -body $output
        Exit 1
    }
}

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Archive-Files{

Param (
    [parameter(Mandatory=$false)]
    [String]
    $tempfolder ="C:\temp\ADP_AU-SFTP\temp",

    [parameter(Mandatory=$false)]
    [String]
    $archive = "C:\temp\ADP_AU-SFTP\archive"
    )

    $timestamp = (Get-Date).ToString("yyyyMMdd-hhmmss")
    $filecount = (Get-ChildItem $tempfolder | Measure-Object).Count

    Try
    {
        If( $filecount -eq 0){
            $output = "No files found under $tempfolder to archive.  Exiting script."
            Write-Host $output -ForegroundColor Red
            Log_ToSplunk -Message $output -Status "Fail"
            Exit 1
        }

        Else{
            Write-Host "$filecount files found. Archiving..." -ForegroundColor Yellow
                Get-ChildItem $tempfolder | foreach{
                    [string]$file = $_
                    $name = $file.Split(".")[0]
                    $ext = $file.Split(".")[1]
                    $newname = $name + "_" + $timestamp + "." + $ext

                    Move-Item -Path "$tempfolder\$file" -Destination "$archive\$newname"
                    }
            }
}
    Catch
    {
        $output = "ERROR: File archiving failed. $($_.Exception.Message)"
        Write-Host $output -ForegroundColor Red
        Log_ToSplunk -Message $output -Status "Fail"
    }
}
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Decrypt-Files{
Param (
    [parameter(Mandatory=$false)]
    [String]
    $tempfolder = "C:\temp\ADP_AU-SFTP\temp",

    [parameter(Mandatory=$false)]
    [String]
    $decryptfolder = "C:\temp\ADP_AU-SFTP\decrypted",

    [parameter(Mandatory=$false)]
    [String]
    $pw = "<password>"
    )

    $decryptfilecount = (Get-ChildItem $decryptfolder | Measure-Object).Count
    $filecount = (Get-ChildItem $tempfolder | Measure-Object).Count

    If ($decryptfilecount -gt 0) {Remove-Item $decryptfolder\*.*}

    If( $filecount -eq 0){
        $ouput = "ERROR: File decryption failed.  On $env:COMPUTERNAME, no files were found in '$tempfolder' to decrypt."
        Write-Host $ouput -ForegroundColor Red
        Log_ToSplunk -Message $ouput -Status "Fail"
        Send_Failure_Email -body $ouput
        Exit 1
        }

        Else{
        # $files = @("USER.CSV", "COSTCENTER.CSV", "POSITION.CSV", "LOCATION.CSV", "DIVISION.CSV")
        $files = Get-ChildItem $tempfolder

        $files | foreach{
            [string]$file = $_
            Write-Host "Decrypting $file..." -ForegroundColor Yellow
                Try
                {
                    cmd /c "C:\Program Files (x86)\gnupg\bin\gpg.exe" --yes --always-trust --pinentry-mode=loopback --ignore-mdc-error --passphrase $pw --output $decryptfolder\$file --decrypt $tempfolder\$file

                    $output = "File '$file' successfully decrypted. Exit code:$LastExitCode."
                    Write-Host $output -ForegroundColor Green
                    Log_ToSplunk -Message $output
                }
                Catch
                {
                    $output = "ERROR: File decryption failed. Exit code:$LastExitCode. $($_.Exception.Message)"
                    Write-Host $output -ForegroundColor Red
                    Log_ToSplunk -Message $output -Status "Fail"
                    Send_Failure_Email -body $output
                }
        }
    }
}

<#
Function Add-TxtFiles{
    $localpath = "C:\temp\ADP_AU-SFTP\decrypted"
    Get-ChildItem $localpath | foreach{
        [string]$file = $_
        $name = $file.Split(".")[0]
        $ext = $file.Split(".")[1]

        $extnew = "txt"
        $newname = $name + "." + $extnew
        Copy-Item "$localpath\$file" -Destination "$localpath\$newname"
        }
}
#>
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Forward-Files{
Param(
    [parameter(Mandatory=$false)]
    [String]
    $localPath = "C:\temp\ADP_AU-SFTP\decrypted",

    [parameter(Mandatory=$false)]
    [String]
    $remotePath = "/Datafeed/",

    [parameter(Mandatory=$false)]
    [String]
    $HostName = "ftp.domainuniversityonline.csod.com",
    # $HostName = "ftp.domainuniversityonline-pilot.csod.com", *Updated 02/19/2019 by user2.  Requested by user21.

    [parameter(Mandatory=$false)]
    [String]
    $username = "domainuniversityonline",

    [parameter(Mandatory=$false)]
    [String]
    $pw = "<password>",
    # $pw = "<password>", *Updated 02/19/2019 by user2.  Requested by user21.

    [parameter(Mandatory=$false)]
    [String]
    $SshHostKeyFingerprint = "ssh-rsa 2048 2594AGSUpUQR+LOS3luOWbsg8bKNHTgfWq/v4KZ0reU="
)

$filecount = (Get-ChildItem $localPath | Measure-Object).Count

If( $filecount -eq 0){
    $output = "ERROR: Cornerstone SFTP file upload failure.  No files were found in '$localPath' for transfer to $HostName."
    Write-Host $output -ForegroundColor Red
    Log_ToSplunk -Message $output -Status "Fail"
    Send_Failure_Email -body $output
    Exit 1
    }
Try
{
    Get-ChildItem $localpath | foreach{
        $path = "$localpath\$_"
        $outPath = $path -replace ".csv",".txt"
        Get-Content -path $path | 
        ForEach-Object {$_ -replace ",","|" } |  
        Out-File -filepath $outPath -encoding Ascii
    }
}
Catch
    {
        $output = "ERROR: Cornerstone SFTP file upload to $HostName failed. $($_.Exception.Message)"
        Write-Host $output -ForegroundColor Red
        Log_ToSplunk -Message $output -Status "Fail"
    }

Try
{
    # Load WinSCP .NET assembly
    Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = $HostName
        UserName = $username
        Password = $pw
        SshHostKeyFingerprint = $SshHostKeyFingerprint
    }
 
    $session = New-Object WinSCP.Session
 
    Try
    {
        # Connect
        $session.Open($sessionOptions) 
        $remotePath = "/Datafeed/" 
 
        Get-ChildItem "$localPath"|foreach{
            $file = "$localPath\$_"
            Write-Host "Uploading $file to $HostName..." -ForegroundColor Yellow

            $session.PutFiles($file, $remotePath, $true).Check()  # '$true' here means that the file will be deleted from the source after the transfer completes.
            Write-Host "Success: $?" -ForegroundColor Cyan
        }

        $output = "Cornerstone SFTP file upload to $HostName was successful. Exit Code: $LASTEXITCODE."
        Write-Host $output -ForegroundColor Green
        Log_ToSplunk -Message $output -Status "Success"
    }
    Finally
        {
            # Disconnect, clean up
            $session.Dispose()
        }
    }
Catch
    {
        $output = "ERROR: Cornerstone SFTP file upload to $HostName failed. $($_.Exception.Message)"
        Write-Host $output -ForegroundColor Red
        Log_ToSplunk -Message $output -Status "Fail"
        Send_Failure_Email -body $output
        Exit 1 
    }
}
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Start-Transfer{
Param (
    [parameter(Mandatory=$false)]
    [String]
    $remotePath = "/store/SP42468/RX/",

    [parameter(Mandatory=$false)]
    [String]
    $localPath = "C:\temp\ADP_AU-SFTP\temp\",

    [parameter(Mandatory=$false)]
    [String]
    $HostName = "files.adppayroll.com.au",

    [parameter(Mandatory=$false)]
    [String]
    $Username = "SP42468",

    [parameter(Mandatory=$false)]
    [String]
    $SshHostKeyFingerprint = "ssh-dss 2048 vytJbeodTX3AWJ9O0lddfQjzONGk+fZXPguueM/2g44=",

    [parameter(Mandatory=$false)]
    [String]
    $SshPrivateKeyPath = "C:\temp\ADP_AU-SFTP\SSH_PGPKeys\Domain_SSH_Private.ppk",

    [parameter(Mandatory=$false)]
    [String]
    $PrivateKeyPassphrase = "<password>"
)

Try
    {
    # Load WinSCP .NET assembly
    Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = $HostName
        UserName = $Username
        SshHostKeyFingerprint = $SshHostKeyFingerprint
        SshPrivateKeyPath = $SshPrivateKeyPath
        PrivateKeyPassphrase = $PrivateKeyPassphrase
        }
 
    $session = New-Object WinSCP.Session

    Try
    {
    # Connect
    $session.Open($sessionOptions) 

    $files = @("USERS.CSV", "COSTCENTER.CSV", "POSITION.CSV", "LOCATION.CSV", "DIVISION.CSV") #This is case sensitive.  Make sure the letter case is the same as that of the file being downloaded.

    Foreach ($file in $files){

        Write-Host "Downloading $file from $HostName..." -ForegroundColor Yellow
        $session.GetFiles($remotePath + $file, $localPath + $file, $true).Check() # '$true' here means that the file will be deleted from the source after the transfer completes.
        }
            $output = "ADP Australia SFTP file download from $HostName was successful."
            Write-Host $output -ForegroundColor Green
            Log_ToSplunk -Message $output -Status "Success"

    }
        Finally
            {
                # Disconnect, clean up
                $session.Dispose()
            }
    }
    Catch
        {
            $output = "ERROR: ADP Australia SFTP file download from $HostName failed. $($_.Exception.Message)"
            Write-Host $output -ForegroundColor Red
            Log_ToSplunk -Message $output -Status "Fail"
            Send_Failure_Email -body $output
            # Exit 1
        }
}

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

    Start-Transfer
    Decrypt-Files
    #Add-TxtFiles
    Forward-Files
    Archive-Files
    Purge-Files

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Exit
