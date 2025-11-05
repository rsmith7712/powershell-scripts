# Import the Active Directory cmdlets
Import-Module ActiveDirectory -ErrorAction Stop

# Prompt for your Domain Admin credentials
$cred = Get-Credential -Message 'Enter Domain Admin credentials'

# Get all Windows–based computer names from AD
$computers = Get-ADComputer -Filter {OperatingSystem -like "*Windows*"} |
             Select-Object -ExpandProperty Name

# Local source file and remote path
$sourceFile = "C:\temp\Win11CompTestV3.ps1"
$remotePath = "C:\temp"

# Prepare an array to hold log entries
$results = @()

foreach ($computer in $computers) {
    $timestamp = Get-Date -Format o

    Write-Host "Applying ExecutionPolicy change on $computer…" -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
            Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
        } -ErrorAction Stop

        Write-Host "✅ Success on $computer" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed on ${computer}: $_" -ForegroundColor Red
    }

    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        try {
            # Establish a remoting session using the provided credentials
            $session = New-PSSession -ComputerName $computer -Credential $cred -ErrorAction Stop

            # Ensure the remote folder exists
            Invoke-Command -Session $session -ScriptBlock {
                param($path)
                if (-not (Test-Path $path)) {
                    New-Item -Path $path -ItemType Directory -Force | Out-Null
                }
            } -ArgumentList $remotePath

            # Copy the file into that folder over the session
            Copy-Item -Path $sourceFile `
                      -Destination $remotePath `
                      -ToSession $session `
                      -Force -ErrorAction Stop

            # Log success
            $results += [PSCustomObject]@{
                Computer  = $computer
                Status    = 'Success'
                Message   = "File copied"
                Timestamp = $timestamp
            }
            Write-Host "✅ [$timestamp] File copied successfully to $computer"
        }
        catch {
            # Log failure
            $results += [PSCustomObject]@{
                Computer  = $computer
                Status    = 'Failed'
                Message   = $_.Exception.Message
                Timestamp = $timestamp
            }
            Write-Warning "❌ [$timestamp] Failed to copy file to ${computer}: $($_.Exception.Message)"
        }
        finally {
            # Clean up the session if it was created
            if ($session) { Remove-PSSession $session }
        }
    }
    else {
        # Log unreachable
        $results += [PSCustomObject]@{
            Computer  = $computer
            Status    = 'Unreachable'
            Message   = 'Ping test failed'
            Timestamp = $timestamp
        }
        Write-Warning "⚠️  [$timestamp] Computer $computer is not reachable"
    }
}

# Export the collected results to CSV
$logPath = "C:\temp\FilePusher_log.csv"
$results | Export-Csv -Path $logPath -NoTypeInformation

Write-Host "Log exported to $logPath"
