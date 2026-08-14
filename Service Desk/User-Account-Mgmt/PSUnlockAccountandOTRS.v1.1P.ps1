#This script will prompt for a username to unlock as well as the admin credentials of the person doing the unlocking
#The script will then unlock the account

#Created 2/13/2016 RK0536
#Last Modified 2/13/2016 RK0536


### Need to add error handling for:
### Invalid AD Credentials
### Username that does not exist in AD

### Also need to:
### Create REST API user in OTRS and change account script runs under
### Publish in Citrix
### Test in Citrix

### To Productionize:
### Copy REST API webservice and user to SRVOTRSPROD
### Change script pointers to write to SRVOTRSPROD


### Import Modules
#import-module activedirectory


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

$OTRSServer = "SRVOTRSProd.example.com"
$OTRSUser = "zapi"
$OTRSPass = "h<}dOIaZKHQOnW!Q4-M!"
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

$OTRSServer = "SRVOTRSProd.example.com"
$OTRSUser = "zapi"
$OTRSPass = "h<}dOIaZKHQOnW!Q4-M!"
$RestURL = "http://$OTRSServer/otrs/nph-genericinterface.pl/Webservice/REST/TicketUpdate/$($TicketNo)?UserLogin=$OTRSUser&Password=$OTRSPass"

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

$OTRSServer = "SRVOTRSProd.example.com"
$OTRSUser = "zapi"
$OTRSPass = "h<}dOIaZKHQOnW!Q4-M!"
$RestURL = "http://$OTRSServer/otrs/nph-genericinterface.pl/Webservice/REST/TicketUpdate/$($TicketNo)??UserLogin=$OTRSUser&Password=$OTRSPass"


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

#Function to render GUI Message Box

function Show-MsgBox
{

 [CmdletBinding()]
  param(
  [Parameter(Position=0, Mandatory=$true)] [string]$Prompt,
  [Parameter(Position=1, Mandatory=$false)] [string]$Title ="",
  [Parameter(Position=2, Mandatory=$false)] [ValidateSet("Information", "Question", "Critical", "Exclamation")] [string]$Icon ="Information",
  [Parameter(Position=3, Mandatory=$false)] [ValidateSet("OKOnly", "OKCancel", "AbortRetryIgnore", "YesNoCancel", "YesNo", "RetryCancel")] [string]$BoxType ="OkOnly",
  [Parameter(Position=4, Mandatory=$false)] [ValidateSet(1,2,3)] [int]$DefaultButton = 1
  )
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
switch ($Icon) {
      "Question" {$vb_icon = [microsoft.visualbasic.msgboxstyle]::Question }
      "Critical" {$vb_icon = [microsoft.visualbasic.msgboxstyle]::Critical}
      "Exclamation" {$vb_icon = [microsoft.visualbasic.msgboxstyle]::Exclamation}
      "Information" {$vb_icon = [microsoft.visualbasic.msgboxstyle]::Information}}
switch ($BoxType) {
      "OKOnly" {$vb_box = [microsoft.visualbasic.msgboxstyle]::OKOnly}
      "OKCancel" {$vb_box = [microsoft.visualbasic.msgboxstyle]::OkCancel}
      "AbortRetryIgnore" {$vb_box = [microsoft.visualbasic.msgboxstyle]::AbortRetryIgnore}
      "YesNoCancel" {$vb_box = [microsoft.visualbasic.msgboxstyle]::YesNoCancel}
      "YesNo" {$vb_box = [microsoft.visualbasic.msgboxstyle]::YesNo}
      "RetryCancel" {$vb_box = [microsoft.visualbasic.msgboxstyle]::RetryCancel}}
switch ($Defaultbutton) {
      1 {$vb_defaultbutton = [microsoft.visualbasic.msgboxstyle]::DefaultButton1}
      2 {$vb_defaultbutton = [microsoft.visualbasic.msgboxstyle]::DefaultButton2}
      3 {$vb_defaultbutton = [microsoft.visualbasic.msgboxstyle]::DefaultButton3}}
$popuptype = $vb_icon -bor $vb_box -bor $vb_defaultbutton
$ans = [Microsoft.VisualBasic.Interaction]::MsgBox($prompt,$popuptype,$title)
return $ans
}

#Function to open a GUI dialog box and return the name of the user to be unlocked
function GetUser()
{
#Call VisualBasic from .NET to render GUI Dialog Box
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
#Prompt for username to unlock via GUI dialog
$UserValid = $false
# Check if AD user exists
while ($UserValid -eq $false)
    {
        $VUser = [Microsoft.VisualBasic.Interaction]::InputBox("Enter user name to unlock", "Unlock a user")
        $Validate = Get-ADUser -Filter {sAMAccountName -eq $VUser}
        Write-Host $Validate
        If
            ($Validate -eq $Null)
            {
                $Continue = Show-MsgBox -Prompt "This account does not exist in Active Directory" -Title "Invalid Account" -Icon Critical -BoxType RetryCancel -DefaultButton 1
                If
                    ($Continue -eq 2)
                    {
                    exit
                    }
                Else
                {
                    $UserValid -eq $False
                }
            }
        Else
            {
                $UserValid = $True
                return $VUser
            }
    }

}

#Function to unlock account

function UnlockAccount([string]$LockedUser)
{

    $TargetServer = $env:USERDNSDOMAIN
    Unlock-ADAccount -Identity $LockedUser -Credential $AdminCredentials -Server $TargetServer
}

#### Main Body

#Get AD Admin Credentials from user

$AdminCredentials = $host.ui.PromptForCredential("Elevated credentials are required", "Please enter your ADMIN account username and password.", "", "NetBiosUserName")

#Get NETBIOS name of user account to be unlocked

$UserAcct = GetUser;
$Customer = $UserAcct + "@example.com"




#Open OTRS Ticket to track the incident

$OTRSArticleBody = "Ticket created by Active Directory Unlock Script";

NewOTRSTicket $OTRSTitle $OTRSQueue $OTRSService $OTRSType $OTRSState $OTRSPriority $UserAcct $OTRSArticleBody

#Check if account is really locked out
$LockOutStatus = (Get-AdUser $UserAcct -Properties *).LockedOut

#If the account is really locked then try to unlock it

If ($LockOutStatus -eq $True)
            {
                #Set LockOutStatus back to null so that success or failure can be determined
                $LockOutStatus = $null
                #Update OTRS Ticket
                $OTRSArticleTitle = "$UserAcct's Account is Locked Out!!"
                $OTRSArticleBody = "Running unlock script to unlock $UserAcct's account..."
                UpdateOTRSTicket $OTRSTicketNo $OTRSOWner $OTRSArticleTitle $OTRSArticleBody
                # Call function to unlock account and then sleep to allow AD status to update
                UnlockAccount($UserAcct)
                Start-Sleep -s 15
                $LockOutStatus = (Get-AdUser $UserAcct -Properties *).LockedOut

                ###Check if unlocking worked

                #If account is still locked then update OTRS ticket to state that further troubleshooting is needed
                #Set the ticket owner as the Analyst who is running the script
                #Leave the ticket open and end the script

                If ($LockOutStatus -eq $True)
                {
                    $OTRSArticleTitle = "Unable to unlock account via script"
                    $OTRSArticleBody = "Unlock script was not able to unlock $UserAcct's Active Directory account.  Further troubleshooting is needed."
                    UpdateOTRSTicket $OTRSTicketNo $OTRSOWner $OTRSArticleTitle $OTRSArticleBody
                    exit
                }

                #If the account is now unlocked close the ticket with a note regarding success

                Else
                {
                    $OTRSArticleBody="$UserAcct's Account has been successfully unlocked!!"
                    CloseOTRSTicket $OTRSTicketNo $OTRSArticleBody
                    exit
                }

            }

#If the account is not locked then update the ticket with a note that further troubleshooting is needed as root cause of login failure
#Set the ticket owner as the analyst who is running the script and end the script

Else
            {
                $OTRSArticleTitle = "Account is not locked out"
                $OTRSArticleBody = "$UserAcct's Account is NOT Locked Out!! - Further investigation is needed as to why they are not able to log in!!"
                UpdateOTRSTicket $OTRSTicketNo $OTRSOWner $OTRSArticleTitle $OTRSArticleBody
                exit
            }
