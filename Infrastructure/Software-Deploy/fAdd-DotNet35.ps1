Function Add-DotNet35()
{
    DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Source:"C:\Software\sxs" /quiet
    $returnvalue = $LASTEXITCODE
    $status = "[STATUS.NetFx3] : Exit Code: " + $LASTEXITCODE + "." # should always be 0 or 3010
    Write-Host $status -ForegroundColor White -BackgroundColor Blue
    return $returnvalue
}#===================[End Function]===================