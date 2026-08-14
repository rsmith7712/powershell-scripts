# You can change the following defaults by altering the below settings:
#


# Set the following to true to enable the setup wizard for first time run
$SetupWizard = $False


# Start of Settings
# Report header
$reportHeader = "DOMAIN VMware Daily Health Status"
# Would you like the report displayed in the local browser once completed ?
$DisplaytoScreen = yes
# Display the report even if it is empty?
$DisplayReportEvenIfEmpty = yes
# Use the following item to define if an email report should be sent once completed
$SendEmail = no
# Please Specify the SMTP server address (and optional port) [servername(:port)]
$SMTPSRV = "smtp-relay.example.com"
# Would you like to use SSL to send email?
$EmailSSL = no
# Please specify the email address who will send the vCheck report
$EmailFrom = "richardsmith@example.com"
# Please specify the email address(es) who will receive the vCheck report (separate multiple addresses with comma)
$EmailTo = "richardsmith@example.com"
# Please specify the email address(es) who will be CCd to receive the vCheck report (separate multiple addresses with comma)
$EmailCc = ""
# Please specify an email subject
$EmailSubject = "DOMAIN VMware Daily Health Check"
# Send the report by e-mail even if it is empty?
$EmailReportEvenIfEmpty = yes
# If you would prefer the HTML file as an attachment then enable the following:
$SendAttachment = no
# Set the style template to use.
$Style = "Clarity"
# Do you want to include plugin details in the report?
$reportOnPlugins = yes
# List Enabled plugins first in Plugin Report?
$ListEnabledPluginsFirst = yes
# Set the following setting to $true to see how long each Plugin takes to run as part of the report
$TimeToRun = yes
# Report on plugins that take longer than the following amount of seconds
$PluginSeconds = yes
# End of Settings

# End of Global Variables
