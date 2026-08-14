#Author: user22
#Date: 2/25/2016
#Use: Mirrors U Drive content with content on server.

$computer = Read-Host "Enter Store Computer"

robocopy "\\SERVER\SHARE\ContentDelivery" "\\$computer\C$\contentdelivery" /mir /purge /r:5