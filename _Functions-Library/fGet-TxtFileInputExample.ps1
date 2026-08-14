


param
(
    [string]$strnmbr,
    [string]$storelist
)
Clear-Host
if($storelist)
{
    if(!(Test-Path $storelist))
    {
        Write-Host "$storelist not found. Please try a different path." -ForegroundColor Cyan
    }
        else
        {
            Write-Host "Processing $storelist" -ForegroundColor Green
            $inputlist = Get-Content $storelist
            $inputlist | 
            ForEach-Object{
                    $strnmbr = $_
                    Write-Host "Processing $strnmbr" -ForegroundColor Green
                }
        }
}
elseif($strnmbr)
{
    Write-Host "Processing $strnmbr" -ForegroundColor Green
}
    else
    {
        $strnmbr = Read-Host "Enter the UFO_NUMBER you wish to add or modify"
        Write-Host "Processing $strnmbr" -ForegroundColor Green
    }