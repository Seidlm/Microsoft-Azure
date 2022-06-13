$EXPIRE_AppId = "bc1972c3-22a0-42db-8830-5abf3f7772a8"
$EXPIRE_secret="a__8Q~DYYUfHPv~Tk5u9bwSGQ4s9NjrLjcahVdyR"

$tenantID = "a0ba2ab3-fde4-4259-856d-e450c46dc691"

$MAIL_AppId = "a7bb08a0-e5ab-43bf-8141-cd0efea0aecd"
$MAIL_secret="_.S5nxth1M72J-wY..q~-~-RRZ-IQIA0kd"



#Connect to GRAPH API
$EXPIRE_tokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $EXPIRE_AppId
    Client_Secret = $EXPIRE_secret
}
$EXPIRE_tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $EXPIRE_tokenBody
$EXPIRE_headers = @{
    "Authorization" = "Bearer $($EXPIRE_tokenResponse.access_token)"
    "Content-type"  = "application/json"
}





# List All Groups to find ID
$URLGetApps = "https://graph.microsoft.com/v1.0/applications"
$AllApps = Invoke-RestMethod -Method GET -Uri $URLGetApps -Headers $EXPIRE_headers

#Build PSCustomObject
$Array = [PSCustomObject]@{
    'Type' = "AZAPP"
    'displayName' = $app.displayName
    'ID' = $App.ID
    'AppID' = $app.appId
    'SecType' = "Secret"
    'Secret' = $item.displayName
    'Secret-EndDate' = (Get-date $item.endDateTime)
}



foreach ($App in $AllApps.value) {

    $URLGetApp = "https://graph.microsoft.com/v1.0/applications/$($App.ID)"
    $App = Invoke-RestMethod -Method GET -Uri $URLGetApp -Headers $EXPIRE_headers

    if ($App.passwordCredentials) {
    
        foreach ($item in $App.passwordCredentials) {
    

            $Array = [PSCustomObject]@{
                'Type' = "AZAPP"
                'displayName' = $app.displayName
                'ID' = $App.ID
                'AppID' = $app.appId
                'SecType' = "Secret"
                'Secret' = $item.displayName
                'Secret-EndDate' = (Get-date $item.endDateTime)
            }


        }
    }

    if ($App.keyCredentials) {
    
        foreach ($item in $App.keyCredentials) {

            $Array = [PSCustomObject]@{
                'Type' = "AZAPP"
                'displayName' = $app.displayName
                'ID' = $App.ID
                'AppID' = $app.appId
                'SecType' = "Zert"
                'Secret' = $item.displayName
                'Secret-EndDate' = (Get-date $item.endDateTime)
            }


        }
    }
}


$servicePrincipals = "https://graph.microsoft.com/v1.0/servicePrincipals"
$SPN = Invoke-RestMethod -Method GET -Uri $servicePrincipals -Headers $EXPIRE_headers

$SPNList = $SPN.value 
$UserNextLink = $SPN."@odata.nextLink"


while ($UserNextLink -ne $null) {

    $SPN = (Invoke-RestMethod -Uri $UserNextLink -Headers $EXPIRE_headers -Method Get -Verbose)
    $UserNextLink = $SPN."@odata.nextLink"
    $SPNList += $SPN.value
}

$SPNList[0]

foreach ($SAML in $SPNList) {
    if ($Saml.passwordCredentials) {
        foreach ($PW in $Saml.passwordCredentials) {

            $Array = [PSCustomObject]@{
                'Type' = "SP"
                'displayName' = $SAML.displayName
                'ID' = $SAML.id
                'AppID' = $Saml.appId
                'SecType' = "Secret"
                'Secret' = $PW.displayName
                'Secret-EndDate' = (Get-date $PW.endDateTime)
            }
        }
        
    }
}


$ExpireringZerts = $Array | Where-Object -Property Secret-EndDate -Value (Get-Date).AddMonths(2) -lt  | Where-Object -Property Secret-EndDate -Value (Get-Date) -gt

foreach ($Zert in $ExpireringZerts) {
    $HTML=$Zert | Convertto-HTML -Fragment -As List
    #Send-MailMessage -SmtpServer $exchangeserver -UseSsl -to 'it@wintersteiger.at' -Body "<br>$HTML<br> " -BodyAsHtml -From 'svc_sco_exchange@WintersteigerAG.onmicrosoft.com' -Subject 'Azure Zert to expire'  -Cc 'seimi@baseit.at' 
    #Send-MailMessage -SmtpServer $exchangeserver -UseSsl -to 'seimi@baseit.at' -Body "<br>$HTML<br> " -BodyAsHtml -From 'svc_sco_exchange@WintersteigerAG.onmicrosoft.com' -Subject 'Azure Zert to expire'  -Cc 'seimi@baseit.at' 

}

$Array