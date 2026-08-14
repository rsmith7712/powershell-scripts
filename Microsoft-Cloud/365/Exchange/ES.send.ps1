get-messagetrackinglog -EventID "RECEIVE" -Start "3/25/2013 2:20:00 PM" -ResultSize Unlimited -Sender "espies@example.com" |select timestamp,Sender,{$_.recipients},messagesubject | export-csv c:\reports\trackingESsend.csv
exit
