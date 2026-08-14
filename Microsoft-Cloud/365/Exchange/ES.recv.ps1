get-messagetrackinglog -EventID "DELIVER" -Start "3/25/2013 2:20:00 PM" -ResultSize Unlimited -Recipient "espies@example.com" |select timestamp,Sender,{$_.recipients},messagesubject | export-csv c:\reports\trackingESrecv.csv
exit
