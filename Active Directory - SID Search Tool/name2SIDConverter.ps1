<#
.LICENSE
    MIT License, Copyright 2024 Richard Smith

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

.DESCRIPTION
    name2SIDConverter-v3-2.ps1

.FUNCTIONALITY
    1. Interactive Selection:
       - Prompts the user to select User, Computer, or Group
    2. Object Name Input:
       - Prompts the user to enter the name of the object to search for
    3. Automatic Formatting for Computer Names:
       - Appends $ to the object name if the selected type is Computer
    4. Search and Export:
       - Searches Active Directory for the object
       - Displays results in the console
       - Exports results to a CSV file (AD_Object_SIDs.csv)

.NOTES
[PROMPT]
    Select the object type you want to search for:
    1. User
    2. Computer
    3. Group
    Enter your choice (1, 2, or 3): 2
    Enter the name of the object to search for: CEO-LT01

[OUTPUT TO CONSOLE]
    SID                           Account       Domain
    ----------------------------- ------------- ----------------
    S-1-5-21-1234567890-23456789  CEO-LT01      example.com

    Results exported to C:\Temp\AD_Object_SIDs.csv

[OUTPUT TO CSV]
    SID,Account,Domain
    S-1-5-21-1234567890-2345678901-8675309-1234,CEO-LT01,example.com

    This script is flexible and works for most AD objects.

    Run this script with sufficient permissions to resolve SIDs within your
    Active Directory environment.


.FUTURE DEVELOPMENT
    -User inputs partial name, all potential objects listed and script asks
        if their object is listed, with an option to select it and return
        results for that object


.HISTORY

2024-12-10:[UPDATES]v3.3


2024-12-09:[UPDATES]v3.2
    Search Loop:
        -Uses a do while loop to repeatedly call the Perform-Search
            function if the user selects y to continue.
    User Decision:
        -After each search, the user is asked if they want to perform
            another search:
            y: Presents the search menu again.
            n: Exits the script and returns to the PowerShell prompt.
    Graceful Exit:
        -Displays a "Goodbye" message when the user exits the script.
    Example Run:
        -First Search:
            User performs a search for CEO-LT01 (Computer).
    Search Results:
        -Displays results or a message that the object was not found.
            Prompt to Continue:
                Would you like to perform another search? (y/n): y
            Exit:
                If n is entered: Exiting script. Goodbye!

2024-12-09:[UPDATES]v3.1
    Folder Creation:
        -Uses Test-Path to check if the C:\Temp folder exists
        -Creates the folder with New-Item if it doesn't exist
    Export Path:
        -Ensures the output CSV file is saved in C:\Temp
    User Feedback:
        -Notifies the user if the folder is created

2024-12-08:[UPDATES]v3
    Interactive Selection:
        -Prompts the user to select User, Computer, or Group
    Object Name Input:
        -Prompts the user to enter the name of the object to search for
    Automatic Formatting for Computer Names:
        -Appends $ to the object name if the selected type is Computer
    Search and Export:
        -Searches Active Directory for the object
        -Displays results in the console
        -Exports results to a CSV file (AD_Object_SIDs.csv)

2024-12-07:[UPDATES]v2.3
    Export to CSV:
        -Uses Export-Csv to save results to a file (AD_Object_SIDs.csv)
        -Each result is saved with SID, Account, and Domain columns
    Domain Parsing:
        -Extracts the domain information from the DistinguishedName
            property, splitting at DC= to build the full domain
    Conditional Export:
        -Only exports to CSV if results are found
    File Path:
        -Customize the $outputFile variable to specify the desired
            file location
    Output:
        -Console: Displays results in a formatted table
        -CSV File: A file named AD_Object_SIDs.csv with the following
            columns: SID | Account | Domain

2024-12-06:[UPDATES]v2.2
    Object Name with $:
        -If querying a computer account, append $ to the SamAccountName (CEO-LT01$)
    Object Type:
        -Ensure $objectType is set to "Computer" for computer accounts
        -User accounts typically have a SamAccountName without a trailing $
        -Computer accounts have a SamAccountName that ends with a $
    Result Check:
        -If the object isn't found, ensure the name and type match correctly
    Bug-Report:
    Error - WARNING: Valid values for attribute 'SamAccountName' should end with '$'; 
    the filter clause '(SamAccountName -eq CEO-LT01 )' may not work as intended.

2024-12-05:[UPDATES]v2.1
    Replace YourObjectName:
        -Replace YourObjectName with the actual name of the user, computer,
            or group you are searching for.
    Set the Object Type:
        -Change $objectType to "User", "Computer", or "Group" depending on
            what you're querying.
    Run the Script:
        -Execute the script in a PowerShell session with Active Directory
            module loaded and proper permissions.
    Explanation:
        -Active Directory Module: 
            The script uses the ActiveDirectory module, which provides
            cmdlets like Get-ADUser, Get-ADComputer, and Get-ADGroup.
        -SID Retrieval: 
            The SID property is explicitly fetched for the specified object.
        -Error Handling: 
            If the object isn't found or an invalid object type is specified,
            the script displays appropriate messages.

2024-12-04:[UPDATES]v2
    System.Security.Principal.SecurityIdentifier:
        -This class is used to translate the SID directly into an NT Account
        -It's more reliable than Win32_SID in some environments
        -It's possible that the SIDs aren't resolvable through the Win32_SID class
    Error Handling:
        -If the SID cannot be translated, it captures the error and marks the entry as "Not Found."
    Domain and Account Separation:
        -The NT account is split into Domain and Account parts for better clarity
    How It Works:
        -Each SID is converted into a SecurityIdentifier object
        -The Translate method resolves the SID to an NT account
        -If resolution fails, "Not Found" is output for that SID
    Bug-Report:
    Error - Fails to return results. No account or domain information displayed

2024-12-03:[CREATED]v1
    List of SIDs:
        -The SIDs are stored in an array for iteration.
    WMI Query:
        -[wmi]"Win32_SID.SID='$sid'" resolves each SID to an AD object.
    Error Handling:
        -If the SID cannot be resolved, it outputs "Not Found."
    Results:
        -A custom object is created for each SID containing SID, AccountName, and ReferencedDomainName.
    Formatted Table:
        -The results are displayed in a neat table.

    Run this script in a PowerShell session with the appropriate permissions to access Active Directory.

.INITIAL-REQUEST
    Initial issue was resolve Windows Active Directory object SID's to associated name

#>
# Output file path
$outputFolder = "C:\Temp"
$outputFile = "$outputFolder\AD_Object_SIDs.csv"

# Ensure the output folder exists
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
    Write-Host "Created folder: $outputFolder"
}
# Import the Active Directory module
Import-Module ActiveDirectory

# Function to perform a search
function Perform-Search {
    # Prompt user to select the object type
    Write-Host "Select the object type you want to search for:"
    Write-Host "1. User"
    Write-Host "2. Computer"
    Write-Host "3. Group"
    $objectTypeChoice = Read-Host "Enter your choice (1, 2, or 3)"

    # Map user input to object type
    switch ($objectTypeChoice) {
        "1" { $objectType = "User" }
        "2" { $objectType = "Computer" }
        "3" { $objectType = "Group" }
        default { 
            Write-Host "Invalid choice. Returning to menu."
            return
        }
    }
    # Prompt for object name
    $objectName = Read-Host "Enter the name of the object to search for: "

    # Append trailing $ if searching for a Computer account
    if ($objectType -eq "Computer" -and -not $objectName.EndsWith('$')) {
        $objectName += "$"
    }
    # Array to store results
    $results = @()

    # Query Active Directory
    try {
        switch ($objectType) {
            "User" {
                $adObject = Get-ADUser -Filter { SamAccountName -eq $objectName } -Properties SID
            }
            "Computer" {
                $adObject = Get-ADComputer -Filter { SamAccountName -eq $objectName } -Properties SID
            }
            "Group" {
                $adObject = Get-ADGroup -Filter { SamAccountName -eq $objectName } -Properties SID
            }
            default {
                throw "Unsupported object type: $objectType"
            }
        }
        # Check if an object was found
        if ($adObject) {
            $results += [PSCustomObject]@{
                SID     = $adObject.SID.Value
                Account = $adObject.Name
                Domain  = $adObject.DistinguishedName -split ',' | Where-Object { $_ -match '^DC=' } -join '.'
            }
            Write-Host "Object found:"
            $results | Format-Table -AutoSize
        } else {
            Write-Host "No object found with the name '$objectName' in Active Directory."
        }
    } catch {
        Write-Host "An error occurred: $_"
    }
    # Export results to CSV if any results were found
    if ($results.Count -gt 0) {
        $results | Export-Csv -Path $outputFile -NoTypeInformation
        Write-Host "Results exported to $outputFile"
    } else {
        Write-Host "No results to export."
    }
}
# Main loop
do {
    Perform-Search
    $continueSearch = Read-Host "Would you like to perform another search? (y/n)"
} while ($continueSearch -eq "y")
Write-Host "Exiting script. Goodbye!"
