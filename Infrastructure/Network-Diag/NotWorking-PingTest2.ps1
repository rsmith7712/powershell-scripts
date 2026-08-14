<# 


URL:
https://devblogs.microsoft.com/scripting/use-powershell-to-test-connectivity-on-remote-servers/

#>

#$servers = “dc1″,”dc3″,”sql1″,”wds1″,”ex1”
#$servers = Import-CSV -Path "C:\temp\Data.csv"
$servers = Get-Content C:\temp\Targets.txt

Foreach($s in $servers)

{
  #if(!(Test-NetConnection -Cn $s -BufferSize 16 -Count 1 -ea 0 -quiet))
  if(!(Test-NetConnection -ComputerName $s))

  {

   “Problem connecting to $s”

   “Flushing DNS”

   ipconfig /flushdns | out-null

   “Registering DNS”

   ipconfig /registerdns | out-null

  “doing a NSLookup for $s”

   nslookup $s

   “Re-pinging $s”

     if(!(Test-NetConnection -ComputerName $s))

      {“Problem still exists in connecting to $s”}

       ELSE {“Resolved problem connecting to $s”} #end if

   } # end if

} # end foreach