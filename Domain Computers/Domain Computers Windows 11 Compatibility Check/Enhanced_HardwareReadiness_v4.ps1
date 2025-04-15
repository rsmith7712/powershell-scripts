[CmdletBinding()]
param (
    [Parameter()]
    [string]$CustomField
)

begin {
    # If the environment variable customFieldName is set and not "null", assign it to $CustomField.
    if ($env:customFieldName -and $env:customFieldName -notlike "null") { 
        $CustomField = $env:customFieldName 
    }
    
    # Import the Active Directory module (for querying AD) if available.
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue

    # Ensure the working directory exists
    $tempDir = "C:\temp\Enhanced_Win11_Hardware_Readiness"
    if (-not (Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    }
    # Define log and CSV file paths.
    $logFile    = "$tempDir\log_hardwareReadiness_v4.txt"
    $resultsCSV = "$tempDir\Enhanced_Winn11_HardwareReadiness_v4.csv"

    # Write-Log helper function for logging with a timestamp.
    function Write-Log {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message
        )
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm")
        $logEntry  = "$timestamp - $Message"
        Add-Content -Path $logFile -Value $logEntry
    }

    # Prompt for domain admin credentials for remote actions.
    Write-Host "Enter your Domain Admin credentials (for remote modifications):"
    $global:DomainAdminCred = Get-Credential
    Write-Log "Script started; Domain admin credential captured."

    # Prompt the user: Option 1 or Option 2.
    $optionChoice = Read-Host "Select an option: (1) Import computer list from file, (2) Query Active Directory for all computers"
    if ($optionChoice -eq "2") {
        # For option 2, prepare export folder and file.
        #$exportDir = "$tempDir\Enhanced_Winn11_HardwareReadiness"
        #if (-not (Test-Path $exportDir)) {
        #    New-Item -Path $exportDir -ItemType Directory -Force | Out-Null
        #}
        $global:resultsCSV = "$tempDir\Enhanced_Win11_HardwareReadiness_v4.csv"
    }
    else {
        # Option 1: use file-based list.
        $global:resultsCSV = "$tempDir\results_hardwareReadiness_v4_option1.csv"
    }

    # Define the Get-HardwareReadiness function.
    function Get-HardwareReadiness {
        # --- Begin Hardware Readiness Function Definition ---
        $exitCode = 0
        [int]$MinOSDiskSizeGB = 64
        [int]$MinMemoryGB     = 4
        [Uint32]$MinClockSpeedMHz = 1000
        [Uint32]$MinLogicalCores  = 2
        [Uint16]$RequiredAddressWidth = 64

        $PASS_STRING = "PASS"
        $FAIL_STRING = "FAIL"
        $FAILED_TO_RUN_STRING = "FAILED TO RUN"
        $UNDETERMINED_CAPS_STRING = "UNDETERMINED"
        $UNDETERMINED_STRING = "Undetermined"
        $CAPABLE_STRING = "Capable"
        $NOT_CAPABLE_STRING = "Not capable"
        $CAPABLE_CAPS_STRING = "CAPABLE"
        $NOT_CAPABLE_CAPS_STRING = "NOT CAPABLE"
        $STORAGE_STRING = "Storage"
        $OS_DISK_SIZE_STRING = "OSDiskSize"
        $MEMORY_STRING = "Memory"
        $SYSTEM_MEMORY_STRING = "System_Memory"
        $GB_UNIT_STRING = "GB"
        $TPM_STRING = "TPM"
        $TPM_VERSION_STRING = "TPMVersion"
        $PROCESSOR_STRING = "Processor"
        $SECUREBOOT_STRING = "SecureBoot"
        $I7_7820HQ_CPU_STRING = "i7-7820hq CPU"

        # Format strings.
        $logFormat = '{0}: {1}={2}. {3}; '
        $logFormatWithUnit = '{0}: {1}={2}{3}. {4}; '
        $logFormatReturnReason = '{0}, '
        $logFormatException = '{0}; '
        $logFormatWithBlob = '{0}: {1}. {2}; '

        $outObject = @{
            returnCode   = -2
            returnResult = $FAILED_TO_RUN_STRING
            returnReason = ""
            logging      = ""
        }

        function Private:UpdateReturnCode {
            param(
                [Parameter(Mandatory = $true)]
                [ValidateRange(-2, 1)]
                [int] $ReturnCode
            )
            switch ($ReturnCode) {
                0 { if ($outObject.returnCode -eq -2) { $outObject.returnCode = $ReturnCode } }
                1 { $outObject.returnCode = $ReturnCode }
                -1 { if ($outObject.returnCode -ne 1) { $outObject.returnCode = $ReturnCode } }
            }
        }

        $Source = @"
using Microsoft.Win32;
using System;
using System.Runtime.InteropServices;

    public class CpuFamilyResult
    {
        public bool IsValid { get; set; }
        public string Message { get; set; }
    }

    public class CpuFamily
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct SYSTEM_INFO
        {
            public ushort ProcessorArchitecture;
            ushort Reserved;
            public uint PageSize;
            public IntPtr MinimumApplicationAddress;
            public IntPtr MaximumApplicationAddress;
            public IntPtr ActiveProcessorMask;
            public uint NumberOfProcessors;
            public uint ProcessorType;
            public uint AllocationGranularity;
            public ushort ProcessorLevel;
            public ushort ProcessorRevision;
        }

        [DllImport("kernel32.dll")]
        internal static extern void GetNativeSystemInfo(ref SYSTEM_INFO lpSystemInfo);

        public enum ProcessorFeature : uint
        {
            ARM_SUPPORTED_INSTRUCTIONS = 34
        }

        [DllImport("kernel32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool IsProcessorFeaturePresent(ProcessorFeature processorFeature);

        private const ushort PROCESSOR_ARCHITECTURE_X86 = 0;
        private const ushort PROCESSOR_ARCHITECTURE_ARM64 = 12;
        private const ushort PROCESSOR_ARCHITECTURE_X64 = 9;

        private const string INTEL_MANUFACTURER = "GenuineIntel";
        private const string AMD_MANUFACTURER = "AuthenticAMD";
        private const string QUALCOMM_MANUFACTURER = "Qualcomm Technologies Inc";

        public static CpuFamilyResult Validate(string manufacturer, ushort processorArchitecture)
        {
            CpuFamilyResult cpuFamilyResult = new CpuFamilyResult();
            if (string.IsNullOrWhiteSpace(manufacturer))
            {
                cpuFamilyResult.IsValid = false;
                cpuFamilyResult.Message = "Manufacturer is null or empty";
                return cpuFamilyResult;
            }
            string registryPath = "HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0";
            SYSTEM_INFO sysInfo = new SYSTEM_INFO();
            GetNativeSystemInfo(ref sysInfo);
            switch (processorArchitecture)
            {
                case PROCESSOR_ARCHITECTURE_ARM64:
                    if (manufacturer.Equals(QUALCOMM_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                    {
                        bool isArmv81Supported = IsProcessorFeaturePresent(ProcessorFeature.ARM_SUPPORTED_INSTRUCTIONS);
                        if (!isArmv81Supported)
                        {
                            string registryName = "CP 4030";
                            long registryValue = (long)Registry.GetValue(registryPath, registryName, -1);
                            long atomicResult = (registryValue >> 20) & 0xF;
                            if (atomicResult >= 2) { isArmv81Supported = true; }
                        }
                        cpuFamilyResult.IsValid = isArmv81Supported;
                        cpuFamilyResult.Message = isArmv81Supported ? "" : "Processor does not implement ARM v8.1 atomic instruction";
                    }
                    else {
                        cpuFamilyResult.IsValid = false;
                        cpuFamilyResult.Message = "The processor isn't currently supported for Windows 11";
                    }
                    break;
                case PROCESSOR_ARCHITECTURE_X64:
                case PROCESSOR_ARCHITECTURE_X86:
                    int cpuFamily = sysInfo.ProcessorLevel;
                    int cpuModel = (sysInfo.ProcessorRevision >> 8) & 0xFF;
                    int cpuStepping = sysInfo.ProcessorRevision & 0xFF;
                    if (manufacturer.Equals(INTEL_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                    {
                        try {
                            cpuFamilyResult.IsValid = true;
                            cpuFamilyResult.Message = "";
                            if (cpuFamily >= 6 -and cpuModel <= 95 -and !(cpuFamily -eq 6 -and cpuModel -eq 85))
                            {
                                cpuFamilyResult.IsValid = false;
                                cpuFamilyResult.Message = "";
                            }
                            else if (cpuFamily -eq 6 -and (cpuModel -eq 142 -or cpuModel -eq 158) -and cpuStepping -eq 9)
                            {
                                string registryName = "Platform Specific Field 1";
                                int registryValue = (int)Registry.GetValue(registryPath, registryName, -1);
                                if ((cpuModel -eq 142 -and registryValue -ne 16) -or (cpuModel -eq 158 -and registryValue -ne 8))
                                {
                                    cpuFamilyResult.IsValid = false;
                                }
                                cpuFamilyResult.Message = "PlatformId " + registryValue;
                            }
                        }
                        catch (Exception ex) {
                            cpuFamilyResult.IsValid = false;
                            cpuFamilyResult.Message = "Exception:" + ex.GetType().Name;
                        }
                    }
                    else if (manufacturer.Equals(AMD_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                    {
                        cpuFamilyResult.IsValid = true;
                        cpuFamilyResult.Message = "";
                        if (cpuFamily -lt 23 -or (cpuFamily -eq 23 -and (cpuModel -eq 1 -or cpuModel -eq 17))) {
                            cpuFamilyResult.IsValid = false;
                        }
                    }
                    else {
                        cpuFamilyResult.IsValid = false;
                        cpuFamilyResult.Message = "Unsupported Manufacturer: " + manufacturer + ", Architecture: " + processorArchitecture + ", CPUFamily: " + sysInfo.ProcessorLevel + ", ProcessorRevision: " + sysInfo.ProcessorRevision;
                    }
                    break;
                default:
                    cpuFamilyResult.IsValid = false;
                    cpuFamilyResult.Message = "Unsupported CPU category. Manufacturer: " + manufacturer + ", Architecture: " + processorArchitecture + ", CPUFamily: " + sysInfo.ProcessorLevel + ", ProcessorRevision: " + sysInfo.ProcessorRevision;
                    break;
            }
            return cpuFamilyResult;
        }
    }
"@

        # Storage check.
        try {
            $osDrive = Get-CimInstance -Class Win32_OperatingSystem | Select-Object -Property SystemDrive
            $osDriveSize = Get-CimInstance -Class Win32_LogicalDisk -Filter "DeviceID='$($osDrive.SystemDrive)'" | `
                Select-Object @{Name = "SizeGB"; Expression = { $_.Size / 1GB -as [int] } }
            if ($null -eq $osDriveSize) {
                UpdateReturnCode -ReturnCode 1
                $outObject.returnReason += $logFormatReturnReason -f $STORAGE_STRING
                $outObject.logging += $logFormatWithBlob -f $STORAGE_STRING, "Storage is null", $FAIL_STRING
                $exitCode = 1
            }
            elseif ($osDriveSize.SizeGB -lt $MinOSDiskSizeGB) {
                UpdateReturnCode -ReturnCode 1
                $outObject.returnReason += $logFormatReturnReason -f $STORAGE_STRING
                $outObject.logging += $logFormatWithUnit -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, ($osDriveSize.SizeGB), $GB_UNIT_STRING, $FAIL_STRING
                $exitCode = 1
            }
            else {
                $outObject.logging += $logFormatWithUnit -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, ($osDriveSize.SizeGB), $GB_UNIT_STRING, $PASS_STRING
                UpdateReturnCode -ReturnCode 0
            }
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormat -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }

        # Memory check.
        try {
            $memory = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | `
                Select-Object @{Name = "SizeGB"; Expression = { $_.Sum / 1GB -as [int] } }
            if ($null -eq $memory) {
                UpdateReturnCode -ReturnCode 1
                $outObject.returnReason += $logFormatReturnReason -f $MEMORY_STRING
                $outObject.logging += $logFormatWithBlob -f $MEMORY_STRING, "Memory is null", $FAIL_STRING
                $exitCode = 1
            }
            elseif ($memory.SizeGB -lt $MinMemoryGB) {
                UpdateReturnCode -ReturnCode 1
                $outObject.returnReason += $logFormatReturnReason -f $MEMORY_STRING
                $outObject.logging += $logFormatWithUnit -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, ($memory.SizeGB), $GB_UNIT_STRING, $FAIL_STRING
                $exitCode = 1
            }
            else {
                $outObject.logging += $logFormatWithUnit -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, ($memory.SizeGB), $GB_UNIT_STRING, $PASS_STRING
                UpdateReturnCode -ReturnCode 0
            }
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $outObject.returnReason += $logFormatReturnReason -f $MEMORY_STRING
            $outObject.logging += $logFormat -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }

        # TPM check.
        try {
            $tpm = Get-Tpm
            if ($null -eq $tpm) {
                UpdateReturnCode -ReturnCode 1
                $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                $outObject.logging += $logFormatWithBlob -f $TPM_STRING, "TPM is null", $FAIL_STRING
                $exitCode = 1
            }
            elseif ($tpm.TpmPresent) {
                $tpmVersion = Get-CimInstance -Class Win32_Tpm -Namespace root\CIMV2\Security\MicrosoftTpm | `
                    Select-Object -Property SpecVersion
                if ($null -eq $tpmVersion.SpecVersion) {
                    UpdateReturnCode -ReturnCode 1
                    $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, "null", $FAIL_STRING
                    $exitCode = 1
                }
                $majorVersion = $tpmVersion.SpecVersion.Split(",")[0] -as [int]
                if ($majorVersion -lt 2) {
                    UpdateReturnCode -ReturnCode 1
                    $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpmVersion.SpecVersion), $FAIL_STRING
                    $exitCode = 1
                }
                else {
                    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpmVersion.SpecVersion), $PASS_STRING
                    UpdateReturnCode -ReturnCode 0
                }
            }
            else {
                if ($tpm.GetType().Name -eq "String") {
                    UpdateReturnCode -ReturnCode -1
                    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
                    $outObject.logging += $logFormatException -f $tpm
                }
                else {
                    UpdateReturnCode -ReturnCode 1
                    $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpm.TpmPresent), $FAIL_STRING
                }
                $exitCode = 1
            }
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }

        # CPU details and validation.
        $cpuDetails;
        try {
            $cpuDetails = @(Get-CimInstance -Class Win32_Processor)[0]
            if ($null -eq $cpuDetails) {
                UpdateReturnCode -ReturnCode 1
                $exitCode = 1
                $outObject.returnReason += $logFormatReturnReason -f $PROCESSOR_STRING
                $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, "CpuDetails is null", $FAIL_STRING
            }
            else {
                $processorCheckFailed = $false
                if ($null -eq $cpuDetails.AddressWidth -or $cpuDetails.AddressWidth -ne $RequiredAddressWidth) {
                    UpdateReturnCode -ReturnCode 1
                    $processorCheckFailed = $true
                    $exitCode = 1
                }
                if ($null -eq $cpuDetails.MaxClockSpeed -or $cpuDetails.MaxClockSpeed -le $MinClockSpeedMHz) {
                    UpdateReturnCode -ReturnCode 1
                    $processorCheckFailed = $true
                    $exitCode = 1
                }
                if ($null -eq $cpuDetails.NumberOfLogicalProcessors -or $cpuDetails.NumberOfLogicalProcessors -lt $MinLogicalCores) {
                    UpdateReturnCode -ReturnCode 1
                    $processorCheckFailed = $true
                    $exitCode = 1
                }
                Add-Type -TypeDefinition $Source
                $cpuFamilyResult = [CpuFamily]::Validate([String]$cpuDetails.Manufacturer, [uint16]$cpuDetails.Architecture)
                $cpuDetailsLog = "{AddressWidth=$($cpuDetails.AddressWidth); MaxClockSpeed=$($cpuDetails.MaxClockSpeed); NumberOfLogicalCores=$($cpuDetails.NumberOfLogicalProcessors); Manufacturer=$($cpuDetails.Manufacturer); Caption=$($cpuDetails.Caption); $($cpuFamilyResult.Message)}"
                if (-not $cpuFamilyResult.IsValid) {
                    UpdateReturnCode -ReturnCode 1
                    $processorCheckFailed = $true
                    $exitCode = 1
                }
                if ($processorCheckFailed) {
                    $outObject.returnReason += $logFormatReturnReason -f $PROCESSOR_STRING
                    $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, ($cpuDetailsLog), $FAIL_STRING
                }
                else {
                    $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, ($cpuDetailsLog), $PASS_STRING
                    UpdateReturnCode -ReturnCode 0
                }
            }
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormat -f $PROCESSOR_STRING, $PROCESSOR_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }

        # SecureBoot check.
        try {
            $isSecureBootEnabled = Confirm-SecureBootUEFI
            $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $CAPABLE_STRING, $PASS_STRING
            UpdateReturnCode -ReturnCode 0
        }
        catch [System.PlatformNotSupportedException] {
            UpdateReturnCode -ReturnCode 1
            $outObject.returnReason += $logFormatReturnReason -f $SECUREBOOT_STRING
            $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $NOT_CAPABLE_STRING, $FAIL_STRING
            $exitCode = 1
        }
        catch [System.UnauthorizedAccessException] {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }

        # i7-7820hq CPU check.
        try {
            $supportedDevices = @('surface studio 2', 'precision 5520')
            $systemInfo = @(Get-CimInstance -Class Win32_ComputerSystem)[0]
            if ($null -ne $cpuDetails) {
                if ($cpuDetails.Name -match 'i7-7820hq cpu @ 2.90ghz') {
                    $modelOrSKUCheckLog = $systemInfo.Model.Trim()
                    if ($supportedDevices -contains $modelOrSKUCheckLog) {
                        $outObject.logging += $logFormatWithBlob -f $I7_7820HQ_CPU_STRING, $modelOrSKUCheckLog, $PASS_STRING
                        $outObject.returnCode = 0
                        $exitCode = 0
                    }
                }
            }
        }
        catch {
            if ($outObject.returnCode -ne 0) {
                UpdateReturnCode -ReturnCode -1
                $outObject.logging += $logFormatWithBlob -f $I7_7820HQ_CPU_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
                $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
                $exitCode = 1
            }
        }

        switch ($outObject.returnCode) {
            0  { $outObject.returnResult = $CAPABLE_CAPS_STRING }
            1  { $outObject.returnResult = $NOT_CAPABLE_CAPS_STRING }
            -1 { $outObject.returnResult = $UNDETERMINED_CAPS_STRING }
            -2 { $outObject.returnResult = $FAILED_TO_RUN_STRING }
        }
        $outObject | ConvertTo-Json -Compress
        # --- End of Function ---
    }

    # Capture the function definition so we can send it to remote sessions.
    $global:HRDefinition = (Get-Command Get-HardwareReadiness).Definition
}

process {
    # Get the list of computers based on the chosen option.
    if ($optionChoice -eq "2") {
        # Option 2: Query Active Directory for all computers.
        try {
            $remoteComputers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
            Write-Log "Discovered $($remoteComputers.Count) computer(s) from Active Directory."
        }
        catch {
            Write-Log "Error querying Active Directory: $($_.Exception.Message)"
            exit
        }
    }
    else {
        # Option 1: Import the list from a text file.
        $computersFile = "C:\Temp\Computers.txt"
        if (-not (Test-Path $computersFile)) {
            Write-Log "Computers file not found at $computersFile. Exiting."
            Write-Error "Computers file not found at $computersFile. Exiting script."
            exit
        }
        $remoteComputers = Get-Content -Path $computersFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        Write-Log "Read $($remoteComputers.Count) computer(s) from $computersFile."
    }

    # Create an array to hold CSV export results.
    $allResults = @()

    foreach ($computer in $remoteComputers) {
        $computer = $computer.Trim()
        
        # For Option 1, perform AD validation; Option 2 already comes from AD.
        if ($optionChoice -ne "2") {
            try {
                $adComputer = Get-ADComputer -Identity $computer -ErrorAction SilentlyContinue
            }
            catch {
                $adComputer = $null
            }
            if (-not $adComputer) {
                Write-Log "Computer '$($computer)' was NOT found in Active Directory. Skipping testing."
                continue
            }
            else {
                Write-Log "Computer '$($computer)' was found in Active Directory."
            }
        }
        else {
            Write-Log "Computer '$($computer)' (from AD query) confirmed in Active Directory."
        }
        
        # Validate DNS resolution.
        try {
            $dnsRecord = Resolve-DnsName -Name $computer -ErrorAction SilentlyContinue
        }
        catch {
            $dnsRecord = $null
        }
        if (-not $dnsRecord) {
            Write-Log "Computer '$($computer)' could NOT be resolved via DNS. Skipping testing."
            continue
        }
        else {
            Write-Log "Computer '$($computer)' was resolved via DNS."
        }

        Write-Log "Processing computer: '$($computer)'"
        $actionTaken = ""
        $resultObject = $null

        # Test remote connectivity using Test-Connection.
        if (Test-Connection -ComputerName $computer -Count 2 -Quiet) {
            Write-Log "Computer '$($computer)' is reachable (ping successful)."
            # Check/enable WinRM on remote if necessary.
            try {
                $winrmStatus = Invoke-Command -ComputerName $computer -Credential $DomainAdminCred -ScriptBlock {
                    $service = Get-Service -Name WinRM -ErrorAction SilentlyContinue
                    if ($service) { return $service.Status } else { return "ServiceNotFound" }
                } -ErrorAction Stop
                if ($winrmStatus -eq "Running") {
                    Write-Log "WinRM is already enabled on '$($computer)'."
                    $actionTaken = "No change; WinRM running"
                }
                else {
                    Write-Log "WinRM is not running on '$($computer)'. Attempting to enable..."
                    Invoke-Command -ComputerName $computer -Credential $DomainAdminCred -ScriptBlock {
                        Enable-PSRemoting -Force -SkipNetworkProfileCheck
                    } -ErrorAction Stop
                    Write-Log "WinRM enabled on '$($computer)' successfully."
                    $actionTaken = "Enabled WinRM"
                }
            }
            catch {
                Write-Log "Error processing WinRM on '$($computer)': $($_.Exception.Message)"
                $actionTaken = "WinRM error: $($_.Exception.Message)"
            }

            # Invoke Get-HardwareReadiness remotely.
            try {
                $rawResult = Invoke-Command -ComputerName $computer -Credential $DomainAdminCred -ArgumentList $HRDefinition -ScriptBlock {
                    param($HRDef)
                    Invoke-Expression $HRDef
                    Get-HardwareReadiness
                } -ErrorAction Stop

                # Convert JSON output to an object.
                $resultObject = $rawResult | ConvertFrom-Json
                Write-Log "Hardware readiness for '$($computer)': Result=$($resultObject.returnResult), Code=$($resultObject.returnCode)"
            }
            catch {
                Write-Log "Error executing Get-HardwareReadiness on '$($computer)': $($_.Exception.Message)"
                $resultObject = @{
                    returnCode   = -2
                    returnResult = "Failed to run remotely - $($_.Exception.Message)"
                    returnReason = ""
                    logging      = ""
                }
            }
        }
        else {
            Write-Log "Computer '$($computer)' is unreachable (Test-Connection failed)."
            $resultObject = @{
                returnCode   = -2
                returnResult = "Unreachable - No ping response"
                returnReason = ""
                logging      = ""
            }
            $actionTaken = "Unreachable"
        }

        # If CustomField is provided, update it accordingly.
        if ($CustomField -and -not [string]::IsNullOrEmpty($CustomField) -and -not [string]::IsNullOrWhiteSpace($CustomField)) {
            switch ($resultObject.returnCode) {
                0  { Ninja-Property-Set -Name $CustomField -Value "Capable" }
                1  { Ninja-Property-Set -Name $CustomField -Value "Not Capable" }
                -1 { Ninja-Property-Set -Name $CustomField -Value "Undetermined" }
                -2 { Ninja-Property-Set -Name $CustomField -Value "Failed To Run" }
                default { Ninja-Property-Set -Name $CustomField -Value "Unknown" }
            }
        }

        # Display the result on screen.
        Write-Host "Result for '$($computer)': $($resultObject.returnResult)"

        # Append result to CSV export list.
        $allResults += [PSCustomObject]@{
            ComputerName = $computer
            ActionTaken  = $actionTaken
            ReturnCode   = $resultObject.returnCode
            ReturnResult = $resultObject.returnResult
            Timestamp    = (Get-Date).ToString("yyyy-MM-dd HH:mm")
        }
    }

    # Export aggregated results.
    $allResults | Export-Csv -Path $resultsCSV -NoTypeInformation -Force
    Write-Log "Results exported to $resultsCSV."
}

end {
    Write-Log "Script completed."
}
