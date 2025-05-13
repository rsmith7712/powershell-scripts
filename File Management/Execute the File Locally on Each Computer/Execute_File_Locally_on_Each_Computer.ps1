# Prompt for Domain Admin credentials at the start of the script
$domainAdminCred = Get-Credential -Message "Please enter Domain Admin credentials"

$computers = Get-Content -Path "C:\temp\computers.txt"
$resultsFolder = "C:\temp\Win11Results"

foreach ($computer in $computers) {
    if (Test-Connection -ComputerName $computer -Quiet) {
        $resultsFile = "\\$computer\C$\temp\Win11_Results_$computer.csv"
        
        # Define the script block and pass the $resultsFile variable explicitly
        $scriptBlock = {
            param($resultsFile)
            
            # Ensure the directory exists
            $resultsFolder = "C:\temp"
            if (-not (Test-Path $resultsFolder)) {
                New-Item -Path $resultsFolder -ItemType Directory
            }

            # Run the executable and output to the results file
            & "C:\temp\WhyNotWin11.exe" | Out-File $resultsFile
        }

        try {
            # Invoke the command with Domain Admin credentials, passing $resultsFile as a parameter
            Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock -ArgumentList $resultsFile -Credential $domainAdminCred
            Write-Host "Executed on $computer and saved results to $resultsFile"
        } catch {
            # Capture the exception message and output it correctly
            $errorMessage = $_.Exception.Message
            Write-Warning "Failed to execute file on ${computer}: $errorMessage"
        }
    } else {
        Write-Warning "$computer is not reachable, skipping..."
        continue  # Skip to the next computer if unreachable
    }
}
