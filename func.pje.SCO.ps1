Function SCOCred
{
    $password = "76492d1116743f0423413b16050a5345MgB8AHAAdQBCAGwAaQBqAC8ANQBYAHQAZQBwAHQAVwBnAGUAdQBKAHIAUQBzAHcAPQA9AHwAYgA2`
                 AGUANwAzADQAMABkAGEANAA3AGMAOAAyADEANQA0ADMAMwBlAGEAOABmADEAMABkADQAYwA3AGUAYQBhAGEAYwAxADUANgA1ADgAOQAxADEA`
                 OABlADEAMAA3ADgAYQA1AGIAYgBiAGUAYQBmADUAOQAzADkAYgBlAGMAZgAwADUAMwA0AGYANABiADUAOAAzAGIANwAwADAAZQA2ADkAMwBh`
                 ADIAMQBmADkANwBhADgAMAA3ADAANwA5AGQA"

    $key = "60 243 190 189 12 33 209 178 246 152 202 52 81 161 122 47 88 114 64 20 159 65 34 198 26 150 61 161 40 139 23 119"
    $passwordSecure = ConvertTo-SecureString -String $password -Key ([Byte[]]$key.Split(" "))
    $cred = New-Object system.Management.Automation.PSCredential("prd\Service-SCORCHRAA", $passwordSecure)
    
    Write-Output $cred
}

Function WebURI
{
    $uri = "http://dkhqscorch01.prd.eccocorp.net:81/Orchestrator2012/Orchestrator.svc"
    
    Write-Output $uri
}

Function Get-EcSCORunbookServer
{
    <#
    .SYNOPSIS
	    Get runbook server object

    .DESCRIPTION
	    Get runbook server object, name and id

    .PARAMETER  Name
	    Name of the runbook server

    .PARAMETER  All
	    Switch to list all runbook servers

    .EXAMPLE
        Get-EcSCORunbookServer -All
        
        returns a object for each runbook sevrer available	    

    .INPUTS
	    String, Boolean

    .OUTPUTS
	    PSObject

    .NOTES
	    Version:		1.0.0
	    Author:			Admin-PJE
	    Creation Date:	12/05/2016
        Module Script:  func.pje.SCO
	    Purpose/Change:	Initial function development
    #>

    [CmdletBinding(DefaultParametersetName="Parameter Set 1")]

    Param 
    (
        [Parameter(Mandatory=$true,
                   ParameterSetName="Parameter Set 1",
                   ValueFromPipeline=$true)]
        [String]$Name,
        [Parameter(Mandatory=$true,
                   ParameterSetName="Parameter Set 2")]
        [Switch]$All
    )

    $ErrorActionPreference = "Continue"

    Try 
    {
        $cred = SCOCred

        $webRequest = Invoke-WebRequest -Uri "$(WebUri)/RunbookServers" -Credential $cred
        [xml]$sco = $webRequest.content
        
        filter content
        {
            if($all)
            {
                $input | ? {$_.name -like "*"}
            }

            else
            {
                $input | ? {$_.name -eq $name}
            }
        }
        
        $sco.feed.entry.content.properties | Content | %{
            $props = @{}
            $props.add('Id',$($_.id.'#text'))
            $props.add('Name',$_.Name)
            $obj = New-Object -TypeName PSObject –Prop $props
            Write-Output $obj
        }
    }

    Catch 
    {
        $_.Exception.Message
    }
}

Function Get-EcSCORunbook
{
    <#
    .SYNOPSIS
	    Get runbook object

    .DESCRIPTION
	    This function retrives one or more runbook objects

    .PARAMETER  Name
	    Name of the runbook

    .PARAMETER  All
	    Switch to list all runbooks from the webservice

    .EXAMPLE
        Get-EcSCORunbook -All
        
        returns all runbook object	    
    
    .EXAMPLE
        Get-EcSCORunbook -Name *sccm*
        
        returns all runbook object where name like sccm

    .INPUTS
	    String, Boolean

    .OUTPUTS
	    PSObject

    .NOTES
	    Version:		1.0.0
	    Author:			Admin-PJE
	    Creation Date:	12/05/2016
        Module Script:  func.pje.SCO
	    Purpose/Change:	Initial function development
    #>

    [CmdletBinding(DefaultParametersetName="Parameter Set 1")]

    Param 
    (
        [Parameter(Mandatory=$true,
                   ParameterSetName="Parameter Set 1")]
        [String]$Name,
        [Parameter(Mandatory=$true,
                   ParameterSetName="Parameter Set 2")]
        [Switch]$All
    )

    $ErrorActionPreference = "Ignore"
  
    $cred = SCOCred

    $rb = Invoke-RestMethod -Uri "$(WebUri)/Runbooks" -Method Get -Credential $cred
    
    filter content
    {
        if($all)
        {
            $input | ? {$_.name -like "*"}
        }

        else
        {
            $input | ? {$_.name -like $name}
        }
    }
    
    $rb.content.properties | content | %{
        
        $param = Invoke-RestMethod -Uri "$(WebUri)/Runbooks(guid'$($_.Id.'#text')')/Parameters" -Method Get -Credential $cred

        $in = $param.content.properties | ?{$_.direction -eq "In"} | %{
            "$($_.name)($($_.type))"
        }

        $out = $param.content.properties | ?{$_.direction -eq "Out"} | %{
            $_.name
        }

        $props = [Ordered]@{}
        $props.add('Id',$($_.Id.'#text'))
        $props.add('FolderId',$($_.FolderId.'#text'))
        $props.add('Name',$_.Name)
        $props.add('Input',$in)
        $props.add('Output',$out)
        $props.add('Desription',$_.Description)
        $props.add('CreatedBy',$_.CreatedBy)
        $props.add('CreationTime',$($_.CreationTime.'#text'))
        $props.add('LastModifiedBy',(Get-ADUser -Identity $($_.LastModifiedBy)).name)
        $props.add('LastModifiedTime',$($_.LastModifiedTime.'#text'))
        $props.add('IsMonitor',$($_.IsMonitor.'#text'))
        $props.add('Path',$_.Path)
        $props.add('CheckedOutBy',$($_.CheckedOutBy.'#text'))
        $props.add('CheckedOutTime',$($_.CheckedOutTime.'#text'))
        $obj = New-Object -TypeName PSObject –Prop $props
        Write-Output $obj
    }
}

# SIG # Begin signature block
# MIIPSAYJKoZIhvcNAQcCoIIPOTCCDzUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/iTMbi/xy0tnof6k+j4ea3wq
# vBWgggyvMIIGEDCCBPigAwIBAgITMAAAACpnbAZ3NwLCSQAAAAAAKjANBgkqhkiG
# 9w0BAQUFADBGMRMwEQYKCZImiZPyLGQBGRYDbmV0MRgwFgYKCZImiZPyLGQBGRYI
# ZWNjb2NvcnAxFTATBgNVBAMTDEVDQ08gUm9vdCBDQTAeFw0xNjAyMDUwNzMxMzRa
# Fw0yMjAyMDUwNzQxMzRaMEsxEzARBgoJkiaJk/IsZAEZFgNuZXQxGDAWBgoJkiaJ
# k/IsZAEZFghlY2NvY29ycDEaMBgGA1UEAxMRRUNDTyBJc3N1aW5nIENBIDIwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDRip52iBQlWT8qIN+ak0QzRJ6d
# LdLikRkFKtLp2DQlx7yC/9L4l+gXa/0DEmvvVfx5hWiY38IaCFEJ5cD4LEzNAn7p
# 85F9J+RXgswlVJIYh1IZ0odEjnWN3amGySTznHtqcsmMAVeOp+YNaKoeupFBaq79
# sm8EvhE3bbwU25I57BKnZ/r72FMBqXXsvgHoLs+wBhUWDh6TEGwyCjgykA+Ve3WJ
# PimuVu1o/AMN4CP89VMitHcGe+dh9bA/WGUm7weHtCLKGm2SjSAdl5JU/8p+ElA0
# BuAg3K4ZCxJn04Ay8/OPHVXLd4Hws2qKCWQOQZJ3CIGz+kv1gWS5WC8fw75xAgMB
# AAGjggLwMIIC7DAQBgkrBgEEAYI3FQEEAwIBAjAjBgkrBgEEAYI3FQIEFgQUsEgv
# YdPesnynh6crqATvWxYCcSwwHQYDVR0OBBYEFKu4DJf1/NKT7bctI5su/7e/CuON
# MDsGCSsGAQQBgjcVBwQuMCwGJCsGAQQBgjcVCPu9RofHhWCJjyGHnMxpge+ZNnqG
# 3O00gqyKYAIBZAIBAzALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNV
# HSMEGDAWgBQ7KkBMT7g2WRcc+DDBVJS5UPWQGzCB/gYDVR0fBIH2MIHzMIHwoIHt
# oIHqhixodHRwOi8vcGtpLmVjY28uY29tL3BraS9FQ0NPJTIwUm9vdCUyMENBLmNy
# bIaBuWxkYXA6Ly8vQ049RUNDTyUyMFJvb3QlMjBDQSxDTj1ES0hRQ0EwMSxDTj1D
# RFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29u
# ZmlndXJhdGlvbixEQz1lY2NvY29ycCxEQz1uZXQ/Y2VydGlmaWNhdGVSZXZvY2F0
# aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50MIIB
# FQYIKwYBBQUHAQEEggEHMIIBAzBOBggrBgEFBQcwAoZCaHR0cDovL3BraS5lY2Nv
# LmNvbS9wa2kvREtIUUNBMDEuZWNjb2NvcnAubmV0X0VDQ08lMjBSb290JTIwQ0Eu
# Y3J0MIGwBggrBgEFBQcwAoaBo2xkYXA6Ly8vQ049RUNDTyUyMFJvb3QlMjBDQSxD
# Tj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049
# Q29uZmlndXJhdGlvbixEQz1lY2NvY29ycCxEQz1uZXQ/Y0FDZXJ0aWZpY2F0ZT9i
# YXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwDQYJKoZIhvcN
# AQEFBQADggEBAIEXlJyIDAVMqSGrleaJmrbgh+dmRssUUUwQQCvtiwTofJrzPCNy
# DWOcEtnXgor83DZW6sU4AUsMFi1opz9GAE362toR//ruyi9cF0vLIh6W60cS2m/N
# vGvgKz7bb235J4tWi0Jj9sCZQ8sFBI61uIlmYiryTEA2bOdAZ5fQX1wide0qCDMi
# CU3yNz4b9VZ7nmB95WKzJ1ZvPjVfTyHBdtK9fhRU/IiJORKzlbMyPxortpCnb0VK
# O/uLYMD4itTk2QxTxx4ZND2Vqi2uJ0dMNO79ELfZ9e9C9jaW2JfEsCxy1ooHsjki
# TpJ+9fNJO7Ws3xru/gINd+G1KdCRG1vYgpswggaXMIIFf6ADAgECAhNYACe/37gE
# fPQoHYROAAIAJ7/fMA0GCSqGSIb3DQEBBQUAMEsxEzARBgoJkiaJk/IsZAEZFgNu
# ZXQxGDAWBgoJkiaJk/IsZAEZFghlY2NvY29ycDEaMBgGA1UEAxMRRUNDTyBJc3N1
# aW5nIENBIDIwHhcNMTYwMjI5MDkzMzUzWhcNMTgwMjI4MDkzMzUzWjCBhjETMBEG
# CgmSJomT8ixkARkWA25ldDEYMBYGCgmSJomT8ixkARkWCGVjY29jb3JwMRMwEQYK
# CZImiZPyLGQBGRYDcHJkMSMwIQYDVQQLExpTZXJ2aWNlIGFuZCBBZG1pbiBBY2Nv
# dW50czEbMBkGA1UEAxMSQWRtaW4tUGFsbGUgSmVuc2VuMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAxmqcSpu1qSLe7vVysjMibrbQeaV9PHz7MMPazFm2
# 5FKRmuCylaMRRZhCfRVRX06qbEVDjujD+ZKd0NJv8SpNO45ibfh5xSguZwHNQByq
# LN3S/VVcjtpuyX5yygzKSMwEzdj/dHCUGl2Aczvg5NmU1y8RTCsLYqj+V1bokAr2
# +nwqWTkZyRd/eoqGsND2DONyIJ2ApXbFnHwcpSq9mgAbbOvMFeyTay07MPUmB+2i
# AnCvr1Uv9YNhsNf3rwDrnYBJCQsZxnRkUBLhzjbb8jfGQUSYdQcjYlFJ2SQWg4Un
# r5w/xY5Tch8gg5G0n3MEdvWLH0YCB0/3r3X4Cw4b/eXJvwIDAQABo4IDNjCCAzIw
# OwYJKwYBBAGCNxUHBC4wLAYkKwYBBAGCNxUI+71Gh8eFYImPIYeczGmB75k2eobL
# pxuE5NYXAgFkAgEJMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIH
# gDAbBgkrBgEEAYI3FQoEDjAMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBQwtdTxDNLj
# LTzwsstoDiLwyETyZDAfBgNVHSMEGDAWgBSruAyX9fzSk+23LSObLv+3vwrjjTCC
# AQ4GA1UdHwSCAQUwggEBMIH+oIH7oIH4hjNodHRwOi8vcGtpLmVjY28uY29tL3Br
# aS9FQ0NPJTIwSXNzdWluZyUyMENBJTIwMi5jcmyGgcBsZGFwOi8vL0NOPUVDQ08l
# MjBJc3N1aW5nJTIwQ0ElMjAyLENOPURLSFFDQTAzLENOPUNEUCxDTj1QdWJsaWMl
# MjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERD
# PWVjY29jb3JwLERDPW5ldD9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/
# b2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwggEmBggrBgEFBQcBAQSC
# ARgwggEUMFgGCCsGAQUFBzAChkxodHRwOi8vcGtpLmVjY28uY29tL3BraS9ES0hR
# Q0EwMy5lY2NvY29ycC5uZXRfRUNDTyUyMElzc3VpbmclMjBDQSUyMDIoMikuY3J0
# MIG3BggrBgEFBQcwAoaBqmxkYXA6Ly8vQ049RUNDTyUyMElzc3VpbmclMjBDQSUy
# MDIsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2Vz
# LENOPUNvbmZpZ3VyYXRpb24sREM9ZWNjb2NvcnAsREM9bmV0P2NBQ2VydGlmaWNh
# dGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MDUGA1Ud
# EQQuMCygKgYKKwYBBAGCNxQCA6AcDBpBZG1pbi1QSkVAcHJkLmVjY29jb3JwLm5l
# dDANBgkqhkiG9w0BAQUFAAOCAQEATns0EOsQVL2xSjiETgb3or1+8QvtwV08E0eR
# pFVAwUrQLRav/a4LYobrHm0zIZ2qg5Zswk9PdQpFN3SjNKNGfBTRWOTJeqQq7GBF
# WlZeA6KCmT17KZYj3omSOOYzrAOnG1l2DaX+z14HIGwdJRZHKL23S2okPyEWumYN
# cSoyear7Tmaqxt0WrQtx+xfUB8dlURzU6cSrCzYDhh73jzrPucID8g2HsXdXgoRx
# X/TNIEY7HY7HWQxIiQxjuv9zs8NMdokowrVTbgmP6bkLOadCYb7bt9mBJNr17jBk
# +UQOIxT8vFCbgNliBl0+ZrBBjNOmnuOd9a9oZNUVdbwlBj3FpzGCAgMwggH/AgEB
# MGIwSzETMBEGCgmSJomT8ixkARkWA25ldDEYMBYGCgmSJomT8ixkARkWCGVjY29j
# b3JwMRowGAYDVQQDExFFQ0NPIElzc3VpbmcgQ0EgMgITWAAnv9+4BHz0KB2ETgAC
# ACe/3zAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkq
# hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGC
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUCHjievmpQV4yFF5LI27R9SoyhFwwDQYJKoZI
# hvcNAQEBBQAEggEAcaDOiseyHH69xuiLR/SX3WMgSeu3y2vG80fVEhunTADC02/N
# Ni83So6stB9LOHPB8BvjcNJHoCsYvHTz1dsLVXEdoT7f2o3/npBP9wXtczx924MJ
# /gXFy2t1YjtAJFBrbQAS5mVG8/W8J6IXXz6964hhPtIKmwcOo9S2Je9HFWEKzBsS
# WNMhUGr/RvMzKWxXLnRbdYq0zBekUJp7XhyFxZxbrCGU/hyIZAPtxMIuMDMdsjVy
# Fn40IG9gIrcDExqyk2S4jExGqxEoFF+/J4OFljcF4ksmWD/JrY+JI1Qa6V4hYGJ4
# GpddgYv5JFS0iRIs8CxtxziF0LpsMliNkxkZRw==
# SIG # End signature block
