
# Function - Logging file
function Logging($pingerror, $Computer, $Service)
{
	$outputfile = "\\SERVER\SHARE\...\log_SplunkServiceStatus.txt";
	
	$timestamp = (Get-Date).ToString();
	
	$logstring = "Computer / Service Status: {0}, {1}, {2}" -f $Computer, $Service.Name, $Service.Status;
	
	"$timestamp - $logstring" | out-file $outputfile -Append;
	
	if ($pingerror -eq $false)
	{
		Write-Host "$timestamp - $logstring";
	}
	else
	{
		Write-Host "$timestamp - $logstring" -foregroundcolor red;
	}
	return $null;
}