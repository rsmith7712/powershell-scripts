# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    CoreServerSetup.ps1

.SYNOPSIS
  Setup script for core servers.
 
.DESCRIPTION
  Determines nanme based on IP, joins domain, reboots and then sets up scheduled tasks.
  
.NOTES
  Version:        1.1
  Author:         user22
  Creation Date:  05/17/2018
  Purpose/Change: Added 'logon as batch' rights grant and computer restart on completion.

.HISTORY
  Version:        1.0 (05/16/2018)
  Purpose/Change: Initial Script Development

.FUNCTIONALITY
    Determines nanme based on IP, joins domain, reboots and then sets up scheduled tasks.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#################################
$Script:ProductName = "CoreServerSetup" #Fill this in. Do not put the "TEAM_" prefix
$ErrorActionPreference = "SilentlyContinue" #Maybe change to "SilentlyContinue" for Production.

# Functions
#################################
$logpath = "C:\Logs"
if(!(Test-Path -Path $logpath))
{
    New-Item -Path $logpath -ItemType Directory -Force
}
$Script:Logfile = "C:\temp\CoreServerSetup.txt"
if(!(Test-Path -Path $Script:Logfile))
{
    New-Item -Path $Script:Logfile -ItemType File -Force
}
function Append-Log($message)
{
    $thetime = get-date -Format HH:mm:ss
	Add-Content $Script:LogFile "$thetime ---- $message"
}

function Log_ToSplunk
{
  [CmdletBinding()]
  Param
  (
    [parameter(Mandatory=$true,
    Position=0)]
    $Message,

    [parameter(Mandatory=$false,
    Position=1)]
    $Type = "Log",

    [parameter(Mandatory=$false,
    Position=2)]
    $Status = "Informational",

    [parameter(Mandatory=$false,
    Position=3)]
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
  Append-Log $Message
}

Function Get-Data($data)
{
	$output = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($data))
	return $output
}

function Get-StoreNum{
    $ipAddress = (Get-NetIPAddress | Where-Object{$_.InterfaceAlias -like "Ethernet*" -AND $_.AddressFamily -eq "IPv4"}).IPAddress
    $ipParsed = $ipAddress.split(".")	
    $thirdOct = $ipParsed[2]
    $secondLength = $ipParsed[1].length
    $thirdLength = $ipParsed[2].length
    Switch($secondLength){
        2{ # Two Digits in 2nd Octet
            Switch($thirdLength){ # "New" IP Scheme
                1{#Adds a 0 for stores with a single digit 3rd octet like 1003
                    $UFO_NUMBER = $ipParsed[1]+"0"+$ipParsed[2]
                    $script:ipScheme = "2"
                    Return $UFO_NUMBER
                    }
                2{
                    $UFO_NUMBER = $ipParsed[1]+$ipParsed[2]
                    $script:ipScheme = "2"
                    Return $UFO_NUMBER
                    }
                3{# Offsite Production(Except 2001) will have a .1xx 3rd octet. ie, 2149A will be 10.21.149.xxx
                    $subSite = $ipParsed[2].substring(1,2)
                    $UFO_NUMBER = $ipParsed[1]+$subSite
                    $script:ipScheme = "3"
                    Return $UFO_NUMBER
                    }
                }
            }
        3{ # Three Digits in 2nd Octet
            Switch($ipParsed[1]){ #Gets the prefix of the store based on the 2nd octet. "Old" IP Scheme
                "200"{$prefix = 2} #Canada
                "202"{$prefix = 1} #US VV and Domain
                "204"{$prefix = 3} #Australia
                "208"{$prefix = 5} #US Domain
                "210"{$prefix = 8} #US Partner3
                "100"{return "2001"} #CA 2001 WAREHOUSE
                "209"{
                    Switch($ipParsed[2]){
                        "50"{$labStore = "1950"}
                        "51"{$labStore = "1951"}
                        "56"{$labStore = "1956"}
                        "59"{$labStore = "1959"}
                        "100"{$labStore = "2950"}
                        "101"{$labStore = "2951"}
                        "102"{$labStore = "2952"}
                        "109"{$labStore = "2959"}
                        "250"{$labStore = "3950"}
                        }
                    Return $labStore
                    }
                }
            Switch($thirdLength){ #Gets the rest of the UFO_NUMBER based on 3rd octet
                1{$suffix = "00$thirdOct"}
                2{$suffix = "0$thirdOct"}
                3{$suffix = "$thirdOct"}
                }
            $UFO_NUMBER = "$prefix"+"$suffix" #Combines to create UFO_NUMBER
            Log_ToSplunk -Message "UFO_NUMBER for this setup will be: $($UFO_NUMBER)"
            return $UFO_NUMBER
            }
        }
    }

function set-autoadminlogon
{
    $winlogon = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $user = "Administrator"
    $pass = '<password>'
    Set-ItemProperty -Path $winlogon -Name "AutoAdminLogon" -Value "1"
    Set-ItemProperty -Path $winlogon -Name "DefaultUserName" -Value $user
    Set-ItemProperty -Path $winlogon -Name "DefaultPassword" -Value $pass
    Log_ToSplunk -Message "Autoadmin logon set.  Restarting and beginning phase 2."
}

function disable-autoadminlogon
{
    $winlogon = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $winlogon -Name "AutoAdminLogon" -Value "0"
}

function join_domain($hostname)
{
    if(Test-Connection -ComputerName "SRV-ADS-DC16" -Count 1 -Quiet)
    {
        Add-Computer -Credential $script:credential -DomainName "example.com" -NewName $hostname -Force
        if($?)
        {
            Log_ToSplunk -Message "Succesfully joined domain"
        }
        else
        {
            Log_ToSplunk -Message "Unable to join domain, exiting script."
            exit
        }
    }
    else 
    {
        Log_ToSplunk -Message "Unable to contact Domain Controller.  Exiting script."
        exit
    }
}

function set_scheduledtask
{
    schtasks.exe /CREATE /XML "C:\temp\CoreServerSync.xml" /RU "domain\domainscheduler" /RP '<password>' /F /TN "CoreServerSync"
    Log_ToSplunk -Message "Scheduled task has been set up."
    
}

Function Add-UserToLoginAsBatch ($UserID) {
    <#
    .SYNOPSIS
    When run administratively this will add a user to the local system's login as batch job rights security policy.
    .DESCRIPTION
    When run administratively this will add a user to the local system's login as batch job rights security policy.
    .PARAMETER UserID
    User ID to add to the local system's login as batch job rights security policy.
    .LINK
    http://www.the-little-things.net   
    .NOTES
    Version:
        1.0.0 - Initial release
    Author:
        Zachary Loeber
    Respect: 
        Code mildy modified from 
        http://www.morgantechspace.com/2014/03/Set-Logon-as-batch-job-rights-to-User-by-Powershell-CSharp-CMD.html

    .EXAMPLE
    Add-UserToLoginAsBatch 'test.user'

    Description
    -----------
    Adds the local user test.user to the login as batch job rights on the local machine.
    #>
    
    $CSharpCode = @'
    using System;
    // using System.Globalization;
    using System.Text;
    using System.Runtime.InteropServices;
    public class LsaWrapper
    {
    // Import the LSA functions
     
    [DllImport("advapi32.dll", PreserveSig = true)]
    private static extern UInt32 LsaOpenPolicy(
        ref LSA_UNICODE_STRING SystemName,
        ref LSA_OBJECT_ATTRIBUTES ObjectAttributes,
        Int32 DesiredAccess,
        out IntPtr PolicyHandle
        );
     
    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
    private static extern long LsaAddAccountRights(
        IntPtr PolicyHandle,
        IntPtr AccountSid,
        LSA_UNICODE_STRING[] UserRights,
        long CountOfRights);
     
    [DllImport("advapi32")]
    public static extern void FreeSid(IntPtr pSid);
     
    [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true, PreserveSig = true)]
    private static extern bool LookupAccountName(
        string lpSystemName, string lpAccountName,
        IntPtr psid,
        ref int cbsid,
        StringBuilder domainName, ref int cbdomainLength, ref int use);
     
    [DllImport("advapi32.dll")]
    private static extern bool IsValidSid(IntPtr pSid);
     
    [DllImport("advapi32.dll")]
    private static extern long LsaClose(IntPtr ObjectHandle);
     
    [DllImport("kernel32.dll")]
    private static extern int GetLastError();
     
    [DllImport("advapi32.dll")]
    private static extern long LsaNtStatusToWinError(long status);
     
    // define the structures
     
    private enum LSA_AccessPolicy : long
    {
        POLICY_VIEW_LOCAL_INFORMATION = 0x00000001L,
        POLICY_VIEW_AUDIT_INFORMATION = 0x00000002L,
        POLICY_GET_PRIVATE_INFORMATION = 0x00000004L,
        POLICY_TRUST_ADMIN = 0x00000008L,
        POLICY_CREATE_ACCOUNT = 0x00000010L,
        POLICY_CREATE_SECRET = 0x00000020L,
        POLICY_CREATE_PRIVILEGE = 0x00000040L,
        POLICY_SET_DEFAULT_QUOTA_LIMITS = 0x00000080L,
        POLICY_SET_AUDIT_REQUIREMENTS = 0x00000100L,
        POLICY_AUDIT_LOG_ADMIN = 0x00000200L,
        POLICY_SERVER_ADMIN = 0x00000400L,
        POLICY_LOOKUP_NAMES = 0x00000800L,
        POLICY_NOTIFICATION = 0x00001000L
    }
     
    [StructLayout(LayoutKind.Sequential)]
    private struct LSA_OBJECT_ATTRIBUTES
    {
        public int Length;
        public IntPtr RootDirectory;
        public readonly LSA_UNICODE_STRING ObjectName;
        public UInt32 Attributes;
        public IntPtr SecurityDescriptor;
        public IntPtr SecurityQualityOfService;
    }
     
    [StructLayout(LayoutKind.Sequential)]
    private struct LSA_UNICODE_STRING
    {
        public UInt16 Length;
        public UInt16 MaximumLength;
        public IntPtr Buffer;
    }
    /// 
    //Adds a privilege to an account
     
    /// Name of an account - "domain\account" or only "account"
    /// Name ofthe privilege
    /// The windows error code returned by LsaAddAccountRights
    public long SetRight(String accountName, String privilegeName)
    {
        long winErrorCode = 0; //contains the last error
     
        //pointer an size for the SID
        IntPtr sid = IntPtr.Zero;
        int sidSize = 0;
        //StringBuilder and size for the domain name
        var domainName = new StringBuilder();
        int nameSize = 0;
        //account-type variable for lookup
        int accountType = 0;
     
        //get required buffer size
        LookupAccountName(String.Empty, accountName, sid, ref sidSize, domainName, ref nameSize, ref accountType);
     
        //allocate buffers
        domainName = new StringBuilder(nameSize);
        sid = Marshal.AllocHGlobal(sidSize);
     
        //lookup the SID for the account
        bool result = LookupAccountName(String.Empty, accountName, sid, ref sidSize, domainName, ref nameSize,
                                        ref accountType);
     
        //say what you're doing
        Console.WriteLine("LookupAccountName result = " + result);
        Console.WriteLine("IsValidSid: " + IsValidSid(sid));
        Console.WriteLine("LookupAccountName domainName: " + domainName);
     
        if (!result)
        {
            winErrorCode = GetLastError();
            Console.WriteLine("LookupAccountName failed: " + winErrorCode);
        }
        else
        {
            //initialize an empty unicode-string
            var systemName = new LSA_UNICODE_STRING();
            //combine all policies
            var access = (int) (
                                    LSA_AccessPolicy.POLICY_AUDIT_LOG_ADMIN |
                                    LSA_AccessPolicy.POLICY_CREATE_ACCOUNT |
                                    LSA_AccessPolicy.POLICY_CREATE_PRIVILEGE |
                                    LSA_AccessPolicy.POLICY_CREATE_SECRET |
                                    LSA_AccessPolicy.POLICY_GET_PRIVATE_INFORMATION |
                                    LSA_AccessPolicy.POLICY_LOOKUP_NAMES |
                                    LSA_AccessPolicy.POLICY_NOTIFICATION |
                                    LSA_AccessPolicy.POLICY_SERVER_ADMIN |
                                    LSA_AccessPolicy.POLICY_SET_AUDIT_REQUIREMENTS |
                                    LSA_AccessPolicy.POLICY_SET_DEFAULT_QUOTA_LIMITS |
                                    LSA_AccessPolicy.POLICY_TRUST_ADMIN |
                                    LSA_AccessPolicy.POLICY_VIEW_AUDIT_INFORMATION |
                                    LSA_AccessPolicy.POLICY_VIEW_LOCAL_INFORMATION
                                );
            //initialize a pointer for the policy handle
            IntPtr policyHandle = IntPtr.Zero;
     
            //these attributes are not used, but LsaOpenPolicy wants them to exists
            var ObjectAttributes = new LSA_OBJECT_ATTRIBUTES();
            ObjectAttributes.Length = 0;
            ObjectAttributes.RootDirectory = IntPtr.Zero;
            ObjectAttributes.Attributes = 0;
            ObjectAttributes.SecurityDescriptor = IntPtr.Zero;
            ObjectAttributes.SecurityQualityOfService = IntPtr.Zero;
     
            //get a policy handle
            uint resultPolicy = LsaOpenPolicy(ref systemName, ref ObjectAttributes, access, out policyHandle);
            winErrorCode = LsaNtStatusToWinError(resultPolicy);
     
            if (winErrorCode != 0)
            {
                Console.WriteLine("OpenPolicy failed: " + winErrorCode);
            }
            else
            {
                //Now that we have the SID an the policy,
                //we can add rights to the account.
     
                //initialize an unicode-string for the privilege name
                var userRights = new LSA_UNICODE_STRING[1];
                userRights[0] = new LSA_UNICODE_STRING();
                userRights[0].Buffer = Marshal.StringToHGlobalUni(privilegeName);
                userRights[0].Length = (UInt16) (privilegeName.Length*UnicodeEncoding.CharSize);
                userRights[0].MaximumLength = (UInt16) ((privilegeName.Length + 1)*UnicodeEncoding.CharSize);
     
                //add the right to the account
                long res = LsaAddAccountRights(policyHandle, sid, userRights, 1);
                winErrorCode = LsaNtStatusToWinError(res);
                if (winErrorCode != 0)
                {
                    Console.WriteLine("LsaAddAccountRights failed: " + winErrorCode);
                }
     
                LsaClose(policyHandle);
            }
            FreeSid(sid);
        }
     
        return winErrorCode;
    }
    }
    
    public class AddUserToLoginAsBatch
    {
        public static void GrantUserLogonAsBatchJob(string userName)
        {
            try
            {
                LsaWrapper lsaUtility = new LsaWrapper();
         
                lsaUtility.SetRight(userName, "SeBatchLogonRight");
         
                Console.WriteLine("Logon as batch job right is granted successfully to " + userName);
            }            
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
        }
    }
'@
    try {
        Add-Type -ErrorAction Stop -Language:CSharpVersion3 -TypeDefinition $CSharpCode
    }
    catch {
        Write-Error $_.Exception.Message
        break
    }
    [AddUserToLoginAsBatch]::GrantUserLogonAsBatchJob($UserID)
}

function set_dns
{
    $interfaceIndex = (Get-NetAdapter -Name "ethernet0").ifIndex
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses ("0.0.0.0","0.0.0.0","0.0.0.0")
    Log_ToSplunk -Message "DNS server addresses set"
}

function phase1
{
    Log_ToSplunk -Message "Beginning Phase 1"
    Append-Log -message "Beginning Phase 1"
    Set-LocalUser -Name "Administrator" -PasswordNeverExpires:$true
    Log_ToSplunk -message "Administrator password set to never expire"
    set_dns
    Copy-Item -Path "C:\temp\CoreServerSetup.bat" -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\CoreServerSetup.bat"
    join_domain $hostname
    set-autoadminlogon
    Restart-Computer -Force
}

function phase2
{
    Log_ToSplunk -Message "Beginning Phase 2"
    set_scheduledtask
    Add-UserToLoginAsBatch "domain\domainscheduler"
    Log_ToSplunk -Message "Granted 'logon as batch' rights to domain\domainscheduler."
    disable-autoadminlogon
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\CoreServerSetup.bat" -Force
    Log_ToSplunk -Message "Setup Complete"
    Restart-Computer -Force
}
    
# Variables
#################################

$UFO_NUMBER = Get-StoreNum
$hostname = $UFO_NUMBER + "CORE"

$C1 = '<password>'
$C2 = 'dAB2AGkAXABzAGwAYwBhAGQAbQBpAG4A'
$username = Get-Data $C2
$password = Get-Data $C1 | ConvertTo-SecureString -AsPlainText -Force
$script:credential = New-Object -TypeName System.Management.Automation.PSCredential($username,$password)

# Script Starts
#################################
Log_ToSplunk -Message "Script Starting." -Type "Begin" -Status "Informational"

if((Get-WmiObject -Class win32_computersystem).partofdomain -eq $true)
{
    phase2
}
else
{
    phase1
}

# Script Ends
#################################
Log_ToSplunk -Message "Script Ending." -Type "End" -Status "Informational"
Restart-Computer -Force