import-module ActiveDirectory 

<#
.CREATED-BY
    johan13

.SUMMARY
    #Set the domain to search at the Server parameter. Run 
    powershell as a user with privilieges in that domain to 
    pass different credentials to the command. 

    #Searchbase is the OU you want to search. By default the 
    command will also search all subOU's. To change this 
    behaviour, change the searchscope parameter. Possible 
    values: Base, onelevel, subtree 

    #Ignore the filter and properties parameters 

.FILENAME
    user_list.ps1

.WEBSITE
    https://gallery.technet.microsoft.com/scriptcenter/Get-list-of-AD-users-in-an-923fd124

#>
$ADUserParams=@{ 
'Server' = 'srv.example.com' 
'Searchbase' = 'DC=domain,DC=com' 
'Searchscope'= 'Subtree' 
'Filter' = '*' 
'Properties' = '*' 
} 
 
#This is where to change if different properties are required. 
 
$SelectParams=@{ 
'Property' = 'SAMAccountname', 'CN', 'title', 'DisplayName', 'Description', 'EmailAddress', 'mobilephone',@{name='businesscategory';expression={$_.businesscategory -join '; '}}, 'office', 'officephone', 'state', 'streetaddress', 'city', 'employeeID', 'Employeenumber', 'enabled', 'lockedout', 'lastlogondate', 'badpwdcount', 'passwordlastset', 'created' 
} 
 
get-aduser @ADUserParams | select-object @SelectParams  | export-csv "c:\temp\users.csv"