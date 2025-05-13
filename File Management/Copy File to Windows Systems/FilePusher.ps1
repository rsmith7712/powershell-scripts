# Import the Active Directory cmdlets
Import-Module ActiveDirectory -ErrorAction Stop

# Prompt for your Domain Admin credentials
$cred = Get-Credential -Message 'Enter Domain Admin credentials'

# Get all Windows–based computer names from AD
$computers = Get-ADComputer -Filter {OperatingSystem -like "*Windows*"} |
             Select-Object -ExpandProperty Name

# Local source file
$sourceFile = "C:\temp\WhyNotWin11.exe"

# Remote destination folder path
$remotePath = "C:\temp"

foreach ($computer in $computers) {
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

            Write-Host "✅ File copied successfully to $computer"
        }
        catch {
            Write-Warning "❌ Failed to copy file to ${computer}: $($_.Exception.Message)"
        }
        finally {
            # Clean up the session if it was created
            if ($session) { Remove-PSSession $session }
        }
    }
    else {
        Write-Warning "⚠️  Computer $computer is not reachable"
    }
}
