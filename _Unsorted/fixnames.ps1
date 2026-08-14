$names = Import-Csv C:\temp\MyHR_PULL.csv | select -Property FULL_NAME

foreach($name in $names)
{
    $firstandinitial = $name.split(",")[1]
    $first = $firstandinitial.split(" ")[1]
    $last = $name.split(",")[0]

    $fullname = $first + " " + $last

    Write-Host $fullname

    $fullname | Out-File C:\temp\hr_names.csv -Append
}