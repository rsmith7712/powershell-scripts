Configuration FileCopyTest {

    # Import the module that contains the resources we're using.
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    # Node for another VM to ensure that the file is there 
    Node 'user9-vm' {

         # The File resource can ensure the state of files, or copy them from a source to a destination with persistent updates.
        File FileCopyTest {
            # DestinationPath = "\\user9vm\C$\...\HelloWorld.txt"
            DestinationPath = "C:\Temp\HelloWorld3.txt"
            Ensure = "Present"
            Contents   = "Hello World from DSC!"
        }
    }
}

# Source: https://docs.microsoft.com/en-us/powershell/dsc/configurations/write-compile-apply-configuration 
# Source: https://docs.microsoft.com/en-us/powershell/dsc/quickstarts/website-quickstart#requirements

# Compile it
FileCopyTest

# Run the configuration on localhost
Start-DscConfiguration -Path .\FileCopyTest -ComputerName user9-vm -Wait -Force -Verbose
