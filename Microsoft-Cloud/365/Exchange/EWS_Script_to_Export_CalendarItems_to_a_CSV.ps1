# LEGAL
<# LICENSE
    MIT License, Copyright 2015 Richard Smith

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
    EWS_Script_to_Export_CalendarItems_to_a_CSV.ps1

.DESCRIPTION
    		Use the script below to export the calendar items of a mailbox into a
    	CSV file.  Please note that the date range has a 2 year/1000 appointment max.
    	Depending on the number of items in the calendar between your date range, you
    	may have to adjust the date range to accommodate the 1000 item limit. Also,
    	give yourself full access to the mailbox you are querying. I used a section
    	of Glen's script because he nailed the attendee's query. Props to Glen!

.FUNCTIONALITY
    		Use the script below to export the calendar items of a mailbox into a
    	CSV file.  Please note that the date range has a 2 year/1000 appointment max.
    	Depending on the number of items in the calendar between your date range, you
    	may have to adjust the date range to accommodate the 1000 item limit. Also,
    	give yourself full access to the mailbox you are querying. I used a section
    	of Glen's script because he nailed the attendee's query. Props to Glen!

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Declare Variables
$EWSDLL = "C:\Program Files\Microsoft\Exchange Server\V15\Bin\Microsoft.Exchange.WebServices.dll"
$MBX = "admin2@example.com"
$EWSURL = "https://srv.example.com/EWS/Exchange.asmx"
$StartDate = (Get-Date).AddDays(-60)
$EndDate = (Get-Date)

#Binding of the calendar of the Mailbox and EWS
Import-Module -Name $EWSDLL
$mailboxname = $MBX
$service = new-object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.Exchangeversion]::exchange2013)
$service.Url = new-object System.Uri($EWSURL)
$folderid = new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Calendar, $MailboxName)
$Calendar = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service, $folderid)
$Recurring = new-object Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition([Microsoft.Exchange.WebServices.Data.DefaultExtendedPropertySet]::Appointment, 0x8223, [Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Boolean);
$psPropset = new-object Microsoft.Exchange.WebServices.Data.PropertySet([Microsoft.Exchange.WebServices.Data.BasePropertySet]::FirstClassProperties)
$psPropset.Add($Recurring)
$psPropset.RequestedBodyType = [Microsoft.Exchange.WebServices.Data.BodyType]::Text;

$RptCollection = @()

$AppointmentState = @{ 0 = "None"; 1 = "Meeting"; 2 = "Received"; 4 = "Canceled"; }

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
	$rptObj = "" | Select StartTime, EndTime, Duration, Type, Subject, Location, Organizer, Attendees, AppointmentState, Notes, HasAttachments, IsReminderSet
	$rptObj.StartTime = $Item.Start
	$rptObj.EndTime = $Item.End
	$rptObj.Duration = $Item.Duration
	$rptObj.Subject = $Item.Subject
	$rptObj.Type = $Item.AppointmentType
	$rptObj.Location = $Item.Location
	$rptObj.Organizer = $Item.Organizer.Address
	$rptObj.HasAttachments = $Item.HasAttachments
	$rptObj.IsReminderSet = $Item.IsReminderSet
	$aptStat = "";
	$AppointmentState.Keys | where { $_ -band $Item.AppointmentState } | foreach { $aptStat += $AppointmentState.Get_Item($_) + " " }
	$rptObj.AppointmentState = $aptStat
	$RptCollection += $rptObj
	foreach ($attendee in $Item.RequiredAttendees)
	{
		$atn = $attendee.Address + "; "
		$rptObj.Attendees += $atn
	}
	foreach ($attendee in $Item.OptionalAttendees)
	{
		$atn = $attendee.Address + "; "
		$rptObj.Attendees += $atn
	}
	foreach ($attendee in $Item.Resources)
	{
		$atn = $attendee.Address + "; "
		$rptObj.Resources += $atn
	}
	$rptObj.Notes = $Item.Body.Text
	#Display on the screen
	"Start:   " + $Item.Start
	"Subject: " + $Item.Subject
}
#Export to a CSVFile
$RptCollection | Export-Csv -NoTypeInformation -Path "c:\$MailboxName-Calendar2CSV.csv"