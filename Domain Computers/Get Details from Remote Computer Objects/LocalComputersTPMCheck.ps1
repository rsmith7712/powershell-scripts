    Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, OSArchitecture, Version | Format-List
    Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer, SystemProductName, SystemManufacturer | Format-List
    Get-TPM