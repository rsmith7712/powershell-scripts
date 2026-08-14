## AD Computer Cleanup Script##################################
#
#
#Script checks computers in Workstations OU and moves them
# to deleted OU. Removes deleted objects from disabled computers
#
#Created by Mark Gevaert
# Original: 1/6/2017
#
#########################################################

#set static variables for script
import-module activedirectory  
$domain = "example.com"  
$DaysInactive = 45  
$time = (Get-Date).Adddays(-($DaysInactive))
$disabledtime = 90
$deltime = (Get-Date).Adddays(-($disabledtime))

#zero out Variables
$OTRSarticlebody = ""
$articlebody = ""


#set static variables for OTRS
$OTRSTitle = "Old Workstation Cleanup (Weekly)"
$OTRSQueue = "Infrastructure IT"
$OTRSService = "IT::Software::ITSM"
$OTRSType = "Monitoring"
$OTRSState = "New"
$UserAcct = "markg"
$OTRSPriority = "2 normal"
$OTRSOwner = $env:USERNAME



#Moves workstations to disabled depending on checkin time
function disablecpus(){
    [string]$moveddisabled = "`n" + "Computers that have been moved to disabled" + "`n"
    $oldcomputers = Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} `
    -searchbase "OU=Workstations,DC=domain,DC=com" `
    -Properties LastLogonTimeStamp | where-object name -like "*" | `
    select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}
    $target = Get-ADOrganizationalUnit -LDAPFilter "(name=Disabled Computers)"
    foreach ($item in $oldcomputers){
        $comp = Get-ADComputer -identity $item.name
        $name = $comp.Name
        $moveddisabled = $moveddisabled + "`n" + $comp
        Move-ADObject $comp -TargetPath $target.DistinguishedName
    }
    return $moveddisabled
}


#deletes computers from Disabled Computers based on time
function deletecpus(){
    [hashtable]$return = @{}
    [string]$deleted = "`n" + "Computers that have been deleted" + "`n"
    [string]$notdeleteddisabled = "`n" + "Computers that are disabled but not deleted" + "`n"
    $disabledcomputers = Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} `
    -searchbase "OU=Disabled Computers,DC=domain,DC=com" `
    -Properties LastLogonTimeStamp | where-object name -like "*" | `
    select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}

    foreach ($object in $disabledcomputers){
        $oldcomp = Get-ADComputer -identity $object.name
        if ($oldcomp.LastLogonDate -lt $deltime){
            $deleted = $deleted + "`n" + $oldcomp.Name
            Remove-ADObject $oldcomp
            }
        else {
            $notdeleteddisabled = $notdeleteddisabled + "`n" + $oldcomp.Name
            $oldcomp.Name
            }
    }
    $Return.notdeleteddisabled = $notdeleteddisabled
    $Return.deleted = $deleted
    return $Return
}

#Data Gathering for OTRS ticket
$Results = deletecpus
$deleted = $Results.deleted
$notdeleteddisabled = $Results.notdeleteddisabled
$moveddisabled = disablecpus
$OTRSarticlebody = $deleted + "`n" + $notdeleteddisabled + $moveddisabled
write-host $OTRSarticlebody

function NewOTRSTicket([string]$Title, [string]$Queue, [string]$Service, [string]$Type, [string]$State, [string]$Priority, [string]$Customer, [string]$TicketBody)
{

$OTRSServer = "SRVOTRSprod.example.com"
$OTRSUser = "zapi"
$OTRSPass = 'h<}dOIaZKHQOnW!Q4-M!'
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

return $r.TicketID

}

function CloseOTRSTicket([string]$TicketNo, [string]$ArticleBody)
{

$OTRSServer = "SRVOTRSprod.example.com"
$OTRSUser = "zapi"
$OTRSPass = 'h<}dOIaZKHQOnW!Q4-M!'
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

$TicketNo = NewOTRSTicket $OTRSTitle $OTRSQueue $OTRSService $OTRSType $OTRSState $OTRSPriority $UserAcct $OTRSArticleBody
$articlebody = "Ticket for information review only."
CloseOTRSTicket $TicketNo $articlebody