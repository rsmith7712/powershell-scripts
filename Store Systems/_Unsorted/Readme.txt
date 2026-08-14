Create two scheduled tasks on each machine.
 1.) Set-IPAddress.ps1
	- Moves machine to it's new IP address and modifies the HOSTS file to reflect the new IPs.
 2.) Set-IPfailsafe.ps1
	- If it can't hit it's new gateway, then it waits for 10 minutes before trying again. It tries 3 times total and if it fails that it reverts to DHCP. Also blanks out the HOSTS file.