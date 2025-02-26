#
# Use this PowerShell script to export the server configuration from a downlevel version of Azure AD Connect 
# that does not support the new JSON settings import and export feature.
#
#  Migration Steps
#
#     Please read the complete instructions for performing an in-place versus a legacy settings migration before
#     attempting the following steps: https://go.microsoft.com/fwlink/?LinkID=2117122
#
#     1.) Copy this script to your production server and save the downlevel server configuration directory
#         to a file share for use in installing a new staging server.
#
#     2.) Run this script on your new staging server and pass in the location of the configuration directory
#         generated in the previous step.  This will create a JSON settings file which can then be imported
#         in the Azure Active Directory Connect tool during Custom installation.
#

Param (
    [Parameter (Mandatory=$false)]
    [string] $ServerConfiguration
)
$helpLink = "https://go.microsoft.com/fwlink/?LinkID=2117122"
$helpMsg = "Please see $helpLink for more information."
$adSyncService = "HKLM:\SYSTEM\CurrentControlSet\services\ADSync"

# An installed wizard is the baseline requirement for this script
$wizard = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Azure AD Connect" -ErrorAction Ignore
if ($wizard.WizardPath)
{
    [version] $wizardVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo($wizard.WizardPath).FileVersion
    try {
        # The ADSync service must be installed in order to extract settings from the production server
        $service = Get-ItemProperty -Path $adSyncService -Name ObjectName -ErrorAction Ignore
        if (!$service.ObjectName)
        {
            Write-Host
            Write-Host "Azure AD Connect must be installed and configured on this server for settings migration to succeed."
            Write-Host "The Microsoft Azure AD Connect synchronization service (ADSync) is not present."
            Write-Host $helpMsg
            exit
        }

        $programData = [IO.Path]::Combine($Env:ProgramData, "AADConnect")
        if (!$ServerConfiguration)
        {
            # Create a temporary directory under %ProgramData%\AADConnect
            $tempDirectory = ("Exported-ServerConfiguration-" + [System.Guid]::NewGuid())
            $ServerConfiguration = [IO.Path]::Combine($programData, $tempDirectory)
        }

        # Export the server configuration in a new PS session to avoid loading legacy cmdLet assemblies
        try
        {
            # try first with new parameter that will validate the configuration 
            Get-ADSyncServerConfiguration -Path $ServerConfiguration $true
        }
        catch [System.Management.Automation.ParameterBindingException]
        {
            Get-ADSyncServerConfiguration -Path $ServerConfiguration
        }

        # Copy over the PersistedState.xml file to the configuration directory
        Copy-Item -Path "$programData\\PersistedState.xml" -Destination $ServerConfiguration

        $author = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $timeCreated = $(Get-Date).ToUniversalTime().ToString("u", [System.Globalization.CultureInfo]::InvariantCulture)
        $policyMetadata = [ordered]@{
            "type" = "migration"
            "author" = $author
            "timeCreated" = $timeCreated
            "azureADConnectVersion" =  $wizardVersion.ToString()
        }

        $hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname
        $serviceParams = Get-ItemProperty -Path "$adSyncService\Parameters" -ErrorAction Ignore
        $databaseServer = $serviceParams.Server
        $databaseInstance = $serviceParams.SQLInstance
        $databaseName = $serviceParams.DBName

        # Retrieve the service account type for documentation purposes (may not be present on old builds)
        $serviceAccountType = "Unknown"
        $msolCoexistence = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\MSOLCoExistence" -ErrorAction Ignore
        if ($msolCoexistence.ServiceAccountType)
        {
            $serviceAccountType = $adSync.ServiceAccountType
        }
        
        [string[]]$connectorIds =(Get-ADSyncConnector | Select-Object -Property Identifier).Identifier

        # NOTE: databaseType is a calculated field and is intentionally ommitted
        $deploymentMetadata = [ordered]@{
            "hostName" = $hostName
            "serviceAccount" = $service.ObjectName
            "serviceAccountType" = $serviceAccountType
            "databaseServer" = $databaseServer
            "databaseInstance" = $databaseInstance
            "databaseName" = $databaseName
            "connectorIds" = $connectorIds
        }

        $policyJSON = [ordered]@{
            "policyMetadata" = $policyMetadata
            "deploymentMetadata" = $deploymentMetadata
        }                 

        # Create MigratedPolicy.json for the production server
        $policyJSON | ConvertTo-Json | Out-File "$ServerConfiguration\MigratedPolicy.json"

        Write-Host
        Write-Host "The downlevel server configuration was successfully exported.  Copy the entire directory to"
        Write-Host "your new staging server and select 'MigratedPolicy.json' from the UI to import these settings."
        Write-Host
        Write-Host "   " $ServerConfiguration
        Write-Host
        Write-Host "Please see $helpLink for more information on completing this process."
    }
    catch {
        Write-Host "Unable to export the server configuration due to an unexpected error."
        Write-Host $helpMsg
        Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    exit
}
else
{
    Write-Host
    Write-Host "The Azure AD Connect tool must be installed on this server for settings migration to succeed."
    Write-Host $helpMsg
}
# SIG # Begin signature block
# MIIoUgYJKoZIhvcNAQcCoIIoQzCCKD8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBFmuzW644A2hIU
# e0doTQIQOOZ59uIfCm+FbtM2rs/A1qCCDYIwggYAMIID6KADAgECAhMzAAAEGNWd
# 9r0q0xSaAAAAAAQYMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjQxMDEwMjAyMDQxWhcNMjUxMDA4MjAyMDQxWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDOebbrIR1gaET8f82uJDUCx+O+4Q563k01RL8NlyfH8Rz74Z+foTJxD+lbljA1
# qc135T/XOfsvj8qAZKEYh+HLlXFJhfI+SwznDD1FDjYnHzvngDn0TtdzrCvlr7/y
# vNFxbs8TAzd9VElRM5bJzszeloZiPrFxDzkWB+OotKHhZGH64i0rnmf/sJT+hbin
# 0oXri9WFxQiDX72OPpCPyXFu9BWn670CIoEclEM7sbLe61r8+w6dS/V1I1/Kys8s
# dPeU6sx4PskR3Vg6iAeNtDKHnZrtpq1mLLZXmWTd5n1tWKPQWPAa5zRzhnoG/XHS
# WjvSg/mqUXboy/XmGu7vVjuVAgMBAAGjggF/MIIBezArBgNVHSUEJDAiBgorBgEE
# AYI3TBMBBgorBgEEAYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUGJLcKTm71PlR
# Aq3HRG3cC0sUfX0wRQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEWMBQGA1UEBRMNMjMzMTEwKzUwMzE4MTAfBgNVHSMEGDAWgBRI
# bmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEt
# MDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAKNZ
# Ji9b6JRZqqcPQMtjLwhbt+1NCU+aFUkY9Z0YbRctiJtJqmxsEwp1ENDLNCV1UssR
# U9sutgvL7qVBaauTYQ6JL9Doeje74UJTLIgHMGkC+dLbHCNqaplmZ9hyFDt5u0rG
# CpXYoqj0o18Rp+ZWJZzJ+m+QLTaC3z0BYvgh1ocHITBbnU/lTb4hIodZQ3Lz6WGe
# LEEfX+85Gs2kIWi4Nr2vAvA0fCyLMwFA9tKo2NhGcmp5Pmfl63i4Mr3ONF66oWK5
# 8UcCVGNP+pNinx3PPRXdOoTvkydQwxRfSE8WC69yWWtUp5maq/TQSR0ijCWKqqMt
# xx34NYwN40lr/EP7+VGEVfdO3Ug38LBk2gxB3SDxYy4AJY9tMYdxTPoh5/kUneZf
# p2my+F23qe2drh/v4wm2NqWsPtvAsz5XDE4Are5r+ERsLzgz7xQhQodB/L6t4f0G
# akkaD2spEyaAHBjNBALjGRG+3lhit9gizkUI+V9GVFyz/Ba7OVGMZYdpV854l30Z
# XI9Uj8FUB+Lw+jcnha6ysNhRBrY0BmMTbfjUp+0BWWwGpwuivhlT+WTuE7Ujazqi
# mvsB2tVg6l1Lk6h7//RXy33lWGIMf5cvel/vVFPgLLDjWZ74DzemVYigVKGqe0uK
# br05DI3dxxpFXObSvTksoQRZyUXXij4O9h+1ESxTMIIHejCCBWKgAwIBAgIKYQ6Q
# 0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNh
# dGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5
# WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQD
# Ex9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4
# BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe
# 0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato
# 88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v
# ++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDst
# rjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN
# 91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4ji
# JV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmh
# D+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbi
# wZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8Hh
# hUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaI
# jAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTl
# UAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNV
# HQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQF
# TuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29m
# dC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNf
# MjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNf
# MjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnlj
# cHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5
# AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oal
# mOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0ep
# o/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1
# HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtY
# SWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInW
# H8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZ
# iWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMd
# YzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7f
# QccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKf
# enoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOpp
# O6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZO
# SEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGiYwghoiAgEBMIGVMH4xCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jv
# c29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAQY1Z32vSrTFJoAAAAABBgw
# DQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIC27rh7y
# 5VXdMTFAmR/PdYFbszAGaWCn5XNWWwWOerkeMEIGCisGAQQBgjcCAQwxNDAyoBSA
# EgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20w
# DQYJKoZIhvcNAQEBBQAEggEAMQM/fyrHHiUKnjmXPLktKjeoOhc2E6ipEuYTMZgO
# GQ3ptmqGnoQehHcRpfObdY6VrNQ3I9Po0O0QCP9W+87Ez0NPH9XAYEN8bw/C37hw
# Ym48e0AWslX+wnGz33sdV5wTf1ORM2iTMpZDtVIyyloQRhseRKjS9L9wKnlqhjY+
# t/LNt/i89FrOjwBdtDQhGp7SaxHr0sEDQimaGsnPZHyRHLoE1uLUR6VK62WA1j75
# rUrYxfpr7K3mOE6CxSIru53WNvaBdI0bnApXDFD905fpKVHppG26EKzpWjUTwZSq
# rqhW4RgP2hI64F8vtE6f3HFJJozy7UkENv7hPIQ0+UbP8KGCF7AwghesBgorBgEE
# AYI3AwMBMYIXnDCCF5gGCSqGSIb3DQEHAqCCF4kwgheFAgEDMQ8wDQYJYIZIAWUD
# BAIBBQAwggFaBgsqhkiG9w0BCRABBKCCAUkEggFFMIIBQQIBAQYKKwYBBAGEWQoD
# ATAxMA0GCWCGSAFlAwQCAQUABCCMXeWYaq7MkbLxIQT+cRMfMAhtLOx+dwiEbGlq
# DwGzxAIGZzIFksuHGBMyMDI0MTExMjAxNDEwMS43MjRaMASAAgH0oIHZpIHWMIHT
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRN
# aWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNVBAsTHm5T
# aGllbGQgVFNTIEVTTjo2QjA1LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaCCEf4wggcoMIIFEKADAgECAhMzAAAB9oMvJmpU
# XSLBAAEAAAH2MA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwMB4XDTI0MDcyNTE4MzEwNFoXDTI1MTAyMjE4MzEwNFowgdMxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29m
# dCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVsZCBU
# U1MgRVNOOjZCMDUtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1T
# dGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0UJe
# LMR/N9WPBZhuKVFF+eWJZ68Wujdj4X6JR05cxO5CepNXo17rVazwWLkm5AjaVh19
# ZVjDChHzimxsoaXxNu8IDggKwpXvpAAItv4Ux50e9S2uVwfKv57p9JKG+Q7VONSh
# ujl1NCMkcgSrPdmd/8zcsmhzcNobLomrCAIORZ8IwhYy4siVQlf1NKhlyAzmkWJD
# 0N+60IiogFBzg3yISsvroOx0x1xSi2PiRIQlTXE74MggZDIDKqH/hb9FT2kK/nV/
# aXjuo9LMrrRmn44oYYADe/rO95F+SG3uuuhf+H4IriXr0h9ptA6SwHJPS2VmbNWC
# jQWq5G4YkrcqbPMax7vNXUwu7T65E8fFPd1IuE9RsG4TMAV7XkXBopmPNfvL0hjx
# g44kpQn384V46o+zdQqy5K9dDlWm/J6vZtp5yA1PyD3w+HbGubS0niEQ1L6wGOrP
# fzIm0FdOn+xFo48ERl+Fxw/3OvXM5CY1EqnzEznPjzJc7OJwhJVR3VQDHjBcEFTO
# vS9E0diNu1eocw+ZCkz4Pu/oQv+gqU+bfxL8e7PFktfRDlM6FyOzjP4zuI25gD8t
# O9zJg6g6fRpaZc439mAbkl3zCVzTLDgchv6SxQajJtvvoQaZxQf0tRiPcbr2HWfM
# oqqd9uiQ0hTUEhG44FBSTeUPZeEenRCWadCW4G8CAwEAAaOCAUkwggFFMB0GA1Ud
# DgQWBBRIwZsJuOcJfScPWcXZuBA4B89K8jAfBgNVHSMEGDAWgBSfpxVdAF5iXYP0
# 5dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIw
# MjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUt
# U3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB
# /wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOC
# AgEA13kBirH1cHu1WYR1ysj125omGtQ0PaQkEzwGb70xtqSoI+svQihsgdTYxaPf
# p2IVFdgjaMaBi81wB8/nu866FfFKKdhdp3wnMZ91PpP4Ooe7Ncf6qICkgSuwgdId
# QvqE0h8VQ5QW5sDV4Q0Jnj4f7KHYx4NiM8C4jTw8SQtsuxWiTH2Hikf3QYB71a7d
# B9zgHOkW0hgUEeWO9mh2wWqYS/Q48ASjOqYw/ha54oVOff22WaoH+/Hxd9NTEU/4
# vlvsRIMWT0jsnNI71jVArT4Q9Bt6VShWzyqraE6SKUoZrEwBpVsI0LMg2X3hOLbl
# C1vxM3+wMyOh97aFOs7sFnuemtI2Mfj8qg16BZTJxXlpPurWrG+OBj4BoTDkC9Ax
# XYB3yEtuwMs7pRWLyxIxw/wV9THKUGm+x+VE0POLwkrSMgjulSXkpfELHWWiCVsl
# JbFIIB/4Alv+jQJSKAJuo9CErbm2qeDk/zjJYlYaVGMyKuYZ+uSRVKB2qkEPcEzG
# 1dO9zIa1Mp32J+zzW3P7suJfjw62s3hDOLk+6lMQOR04x+2o17G3LceLkkxJm41E
# rdiTjAmdClen9yl6HgMpGS4okjFCJX+CpOFX7gBA3PVxQWubisAQbL5HgTFBtQNE
# zcCdh1GYw/6nzzNNt+0GQnnobBddfOAiqkzvItqXjvGyK1QwggdxMIIFWaADAgEC
# AhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQg
# Um9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVa
# Fw0zMDA5MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7V
# gtP97pwHB9KpbE51yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeF
# RiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3X
# D9gmU3w5YQJ6xKr9cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoP
# z130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+
# tVSP3PoFVZhtaDuaRr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5Jas
# AUq7vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/b
# fV+AutuqfjbsNkz2K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuv
# XsLz1dhzPUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg
# 8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzF
# a/ZcUlFdEtsluq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqP
# nhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEw
# IwYJKwYBBAGCNxUCBBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSf
# pxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBB
# MD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0Rv
# Y3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGC
# NxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8w
# HwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmg
# R4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWlj
# Um9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEF
# BQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29D
# ZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEs
# H2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHk
# wo/7bNGhlBgi7ulmZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinL
# btg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCg
# vxm2EhIRXT0n4ECWOKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsId
# w2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2
# zsZ0/fZMcm8Qq3UwxTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23K
# jgm9swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beu
# yOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/
# tM4+pTFRhLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjm
# jJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBj
# U02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYIDWTCCAkECAQEwggEBoYHZpIHWMIHT
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRN
# aWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNVBAsTHm5T
# aGllbGQgVFNTIEVTTjo2QjA1LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAFU9eSpdxs0a06JFI
# uGFHIj/I+36ggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAN
# BgkqhkiG9w0BAQsFAAIFAOrdLNAwIhgPMjAyNDExMTIwMTI0MzJaGA8yMDI0MTEx
# MzAxMjQzMlowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA6t0s0AIBADAKAgEAAgID
# yAIB/zAHAgEAAgIS/TAKAgUA6t5+UAIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgor
# BgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBCwUA
# A4IBAQCGtQqr1b0WKgmZhNQAr/kDSgKA7N9meHFr2tpnfl2IQW1SaWpITNtqr/AS
# faP8vImxRxrAhOkfqS96VAgDcJmUOoMRjYBP/2XfoU/aJYn/rjRGNkq5E7vkxhRn
# yVpvRJVFLuQr/Y2zw0X1LODaVDvs2XyB6CNvZ9cHhu6gOhabT0NQfunto2U80PGv
# S5xhOrI1JlUzGslxnf9Q6j8wouCZmVZ52SFxJ0wXTRSu4pdmSyDwwPEuTDwBXBXv
# JQnd4QmnZQaefa5pRZROl8EB5tjDzPaPkkrocrXG/rP4wLJ9DKQkusfdakriPhXR
# qMupLoumFD0qGTBPG17vlve1fcgnMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTACEzMAAAH2gy8malRdIsEAAQAAAfYwDQYJYIZIAWUD
# BAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0B
# CQQxIgQghWqfdFhmj7xELqyKLh26ZOF4IgdiZCeO97Mf9Ce+COswgfoGCyqGSIb3
# DQEJEAIvMYHqMIHnMIHkMIG9BCArYUzxlF6m5USLS4f8NXL/8aoNEVdsCZRmF+Ll
# QjG2ojCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB
# 9oMvJmpUXSLBAAEAAAH2MCIEIO69hykDuHTPhEFYfBy2VQzPvjhOHGkdUEeb/tQU
# Fxm8MA0GCSqGSIb3DQEBCwUABIICACdNp9f/h9bpZ1mSCjbP4lzj7zNrJgK0zv1f
# uLWZ3JbDTPDENbImWfT3OWNcShWjKpa8/Jhwv2qsV7HZoZlocRW3s5FsPz08IPGT
# 7HjAIWkh5xrgU5yRqlQwX6yB0vLlU5EQWwfyBy6gFMpTpj0/6bMsY+MwowyeQwxo
# hk9nEXyyqMymmh3cyCC1ARHG5Znhjtfl8li/Hz38W+4ZwaVdeSOhqkg2VJp09NKb
# g9p3cregjZ1uV6EQJTwSRVVwj5iOndQAGp9F+pDU0Ze8R8Ej/CJ1zFDmco+Tf2/J
# 820IZukczo3JtgkDPBDwRtzCQiy+DX/wehDHGN7m46qPqGfeUoiE7vN7tgBev726
# DepOXeFOVJHXYDD0MtsyWS+5FETbTvKvLohCns+jq8vFsy9xANo4tEvonJHG7jnZ
# p76GMAQPzHesN7rTOuM/bsKxffnYFQ2Tgms9BSp+nwFul3e7rx/RmCK5XhfdY4LP
# z6PI56NEKsl49EbHk5Q8KOlSgx2EUMd140t3hHorruRNwJbxMt8f8yXbmO/RpKGF
# 64xpQgsiSOpKsjnGGiP6uSdZkAZwNFOWVyHXEQXYNnlMbvPeUZ7+rgrwNBFmUtJC
# L3WjIyz1o808IIARJ3fP52Qp0BBrYnAnzp8WNakQUfpAUO8WWA8TBviY9y2O4kFM
# bOkiDCDR
# SIG # End signature block
