# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    OTRSPowershell.ps1

.DESCRIPTION
    Creates an OTRS help-desk ticket for an Active Directory account lockout with predefined queue, service and priority values.

.FUNCTIONALITY
    Creates an OTRS ticket for account lockout.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



#Set static variables


$OTRSTitle = "Active Directory Account is Locked Out"
$OTRSQueue = "Solutions Desk"
$OTRSService = "Common::Software::Login (password reset/account lockout)"
$OTRSType = "Incident"
$OTRSState = "New"
$OTRSPriority = "2 normal"
$OTRSOwner = $env:USERNAME


#Function to Create New OTRS Ticket


function NewOTRSTicket([string]$Title, [string]$Queue, [string]$Service, [string]$Type, [string]$State, [string]$Priority, [string]$Customer, [string]$TicketBody)
{

$OTRSServer = "SRVOTRSTest.example.com"
$OTRSUser = "jams"
$OTRSPass = "<password>"
$RestURL = "http://$OTRSServer/otrs/nph-genericinterface.pl/Webservice/REST/TicketCreate?UserLogin=$OTRSUser&Password=$OTRSPass"
$OTRSTicketBody = $TicketBody


$OTRSTicket = @{
    Ticket=@{
    Title=$Title;
    Queue=$Queue;
    Service=$Service;
	Type=$Type;
    State=$State;
    Priority=$Priority;
    CustomerUser=$Customer;
  };
  Article=@{
		Subject=$Title;
    Body="$OTRSTicketBody";
    ContentType="text/plain; charset=utf8";
  };
} | ConvertTo-Json

$r = Invoke-RestMethod $RestURL -Method Post -Body $OTRSTicket

if ( $r.Error ) {
  Throw "Unable to create ticket: $( $r.Error.ErrorMessage )"
} else {
  Write-Host "Ticket created: $( $r.TicketNumber ) ($( $r.TicketID ))"
}

Set-Variable -Name OTRSTicketNo -Value $r.TicketNumber -Scope 1

}

function UpdateOTRSTicket([string]$TicketNo, [string]$Owner, [string]$Title, [string]$ArticleBody)
{

$OTRSServer = "SRVOTRSTest.example.com"
$OTRSUser = "jams"
$OTRSPass = "<password>"
$RestURL = "http://$OTRSServer/otrs/nph-genericinterface.pl/Webservice/REST/TicketUpdate?UserLogin=$OTRSUser&Password=$OTRSPass&TicketNumber=$TicketNo"

$OTRSTicket = @{
    Ticket=@{
    Owner=$Owner;
    Responsible=$Owner;
  };
  Article=@{
		Subject=$Title;
        Body=$ArticleBody;
        ContentType="text/plain; charset=utf8";
  };
} | ConvertTo-Json

$r = Invoke-RestMethod $RestURL -Method Post -Body $OTRSTicket



}


function CloseOTRSTicket([string]$TicketNo, [string]$ArticleBody)
{

$OTRSServer = "SRVOTRSTest.example.com"
$OTRSUser = "jams"
$OTRSPass = "<password>"
$RestURL = "http://$OTRSServer/otrs/nph-genericinterface.pl/Webservice/REST/TicketUpdate?UserLogin=$OTRSUser&Password=$OTRSPass&TicketNumber=$TicketNo"


$OTRSTicket = @{
    Ticket=@{
    State="closed successful";
  };
  Article=@{
		Subject="Closed Successful";
        Body=$ArticleBody;
        ContentType="text/plain; charset=utf8";
  };
} | ConvertTo-Json

$r = Invoke-RestMethod $RestURL -Method Post -Body $OTRSTicket
}

