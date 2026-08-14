# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    Export_Calendar_Items_to_a_CSV.ps1

.DESCRIPTION
    		A description of the file.

.FUNCTIONALITY
    		A description of the file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

## Get the Mailbox to Access from the 1st commandline argument

$MailboxName = $args[0]

## Load Managed API dll  
###CHECK FOR EWS MANAGED API, IF PRESENT IMPORT THE HIGHEST VERSION EWS DLL, ELSE EXIT
$EWSDLL = (($(Get-ItemProperty -ErrorAction SilentlyContinue -Path Registry::$(Get-ChildItem -ErrorAction SilentlyContinue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Exchange\Web Services' | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty Name)).'Install Directory') + "Microsoft.Exchange.WebServices.dll")
if (Test-Path $EWSDLL)
{
	Import-Module $EWSDLL
}
else
{
	"$(get-date -format yyyyMMddHHmmss):"
	"This script requires the EWS Managed API 1.2 or later."
	"Please download and install the current version of the EWS Managed API from"
	"http://go.microsoft.com/fwlink/?LinkId=255472"
	""
	"Exiting Script."
	exit
}

## Set Exchange Version  
$ExchangeVersion = [Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2010_SP1

## Create Exchange Service Object  
$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService($ExchangeVersion)

## Set Credentials to use two options are availible Option1 to use explict credentials or Option 2 use the Default (logged On) credentials  

#Credentials Option 1 using UPN for the windows Account  
$psCred = Get-Credential
$creds = New-Object System.Net.NetworkCredential($psCred.UserName.ToString(), $psCred.GetNetworkCredential().password.ToString())
$service.Credentials = $creds
#Credentials Option 2  
#service.UseDefaultCredentials = $true  

## Choose to ignore any SSL Warning issues caused by Self Signed Certificates  

## Code From http://poshcode.org/624
## Create a compilation environment
$Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
$Compiler = $Provider.CreateCompiler()
$Params = New-Object System.CodeDom.Compiler.CompilerParameters
$Params.GenerateExecutable = $False
$Params.GenerateInMemory = $True
$Params.IncludeDebugInformation = $False
$Params.ReferencedAssemblies.Add("System.DLL") | Out-Null

$TASource = @'
  namespace Local.ToolkitExtensions.Net.CertificatePolicy{
    public class TrustAll : System.Net.ICertificatePolicy {
      public TrustAll() { 
      }
      public bool CheckValidationResult(System.Net.ServicePoint sp,
        System.Security.Cryptography.X509Certificates.X509Certificate cert, 
        System.Net.WebRequest req, int problem) {
        return true;
      }
    }
  }
'@
$TAResults = $Provider.CompileAssemblyFromSource($Params, $TASource)
$TAAssembly = $TAResults.CompiledAssembly

## We now create an instance of the TrustAll and attach it to the ServicePointManager
$TrustAll = $TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
[System.Net.ServicePointManager]::CertificatePolicy = $TrustAll

## end code from http://poshcode.org/624

## Set the URL of the CAS (Client Access Server) to use two options are availbe to use Autodiscover to find the CAS URL or Hardcode the CAS to use  

#CAS URL Option 1 Autodiscover  
$service.AutodiscoverUrl($MailboxName, { $true })
"Using CAS Server : " + $Service.url

#CAS URL Option 2 Hardcoded  

#$uri=[system.URI] "https://casservername/ews/exchange.asmx"  
#$service.Url = $uri    

## Optional section for Exchange Impersonation  

#$service.ImpersonatedUserId = new-object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress, $MailboxName) 

# Bind to the Calendar Folder
$folderid = new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Calendar, $MailboxName)
$Calendar = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service, $folderid)
$Recurring = new-object Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition([Microsoft.Exchange.WebServices.Data.DefaultExtendedPropertySet]::Appointment, 0x8223, [Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Boolean);
$psPropset = new-object Microsoft.Exchange.WebServices.Data.PropertySet([Microsoft.Exchange.WebServices.Data.BasePropertySet]::FirstClassProperties)
$psPropset.Add($Recurring)
$psPropset.RequestedBodyType = [Microsoft.Exchange.WebServices.Data.BodyType]::Text;

$AppointmentState = @{ 0 = "None"; 1 = "Meeting"; 2 = "Received"; 4 = "Canceled"; }

#Define Date to Query 
$StartDate = (Get-Date)
$EndDate = (Get-Date).AddDays(7)

$RptCollection = @()


#Define the calendar view  
$CalendarView = New-Object Microsoft.Exchange.WebServices.Data.CalendarView($StartDate, $EndDate, 1000)
$fiItems = $service.FindAppointments($Calendar.Id, $CalendarView)
if ($fiItems.Items.Count -gt 0)
{
	$type = ("System.Collections.Generic.List" + '`' + "1") -as "Type"
	$type = $type.MakeGenericType("Microsoft.Exchange.WebServices.Data.Item" -as "Type")
	$ItemColl = [Activator]::CreateInstance($type)
	foreach ($Item in $fiItems.Items)
	{
		$ItemColl.Add($Item)
	}
	[Void]$service.LoadPropertiesForItems($ItemColl, $psPropset)
}
foreach ($Item in $fiItems.Items)
{
	$rptObj = "" | Select StartTime, EndTime, Duration, Type, Subject, Location, Organizer, Attendees, Resources, AppointmentState, Notes, HasAttachments, IsReminderSet, ReminderDueBy
	$rptObj.StartTime = $Item.Start
	$rptObj.EndTime = $Item.End
	$rptObj.Duration = $Item.Duration
	$rptObj.Subject = $Item.Subject
	$rptObj.Type = $Item.AppointmentType
	$rptObj.Location = $Item.Location
	$rptObj.Organizer = $Item.Organizer.Address
	$rptObj.HasAttachments = $Item.HasAttachments
	$rptObj.IsReminderSet = $Item.IsReminderSet
	$rptObj.ReminderDueBy = $Item.ReminderDueBy
	$aptStat = "";
	$AppointmentState.Keys | where { $_ -band $Item.AppointmentState } | foreach { $aptStat += $AppointmentState.Get_Item($_) + " " }
	$rptObj.AppointmentState = $aptStat
	$RptCollection += $rptObj
	foreach ($attendee in $Item.RequiredAttendees)
	{
		$atn = $attendee.Address + " Required "
		if ($attendee.ResponseType -ne $null)
		{
			$atn += $attendee.ResponseType.ToString() + "; "
		}
		else
		{
			$atn += "; "
		}
		$rptObj.Attendees += $atn
	}
	foreach ($attendee in $Item.OptionalAttendees)
	{
		$atn = $attendee.Address + " Optional "
		if ($attendee.ResponseType -ne $null)
		{
			$atn += $attendee.ResponseType.ToString() + "; "
		}
		else
		{
			$atn += "; "
		}
		$rptObj.Attendees += $atn
	}
	foreach ($attendee in $Item.Resources)
	{
		$atn = $attendee.Address + " Resource "
		if ($attendee.ResponseType -ne $null)
		{
			$atn += $attendee.ResponseType.ToString() + "; "
		}
		else
		{
			$atn += "; "
		}
		$rptObj.Resources += $atn
	}
	$rptObj.Notes = $Item.Body.Text
	"Start    : " + $Item.Start
	"Subject     : " + $Item.Subject
	
}
$RptCollection | Export-Csv -NoTypeInformation -Path "c:\$MailboxName-Calendar1CSV.csv"