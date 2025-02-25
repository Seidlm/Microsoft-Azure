#Settings
$TimeSpanInDays = 90
$MailSender = "Mail Sender Mail"
$MailRecipient = "Mail Recipient Mail"

#Azure App Credentials to get Apps and SP
$EXPIRE_AppId = "your EXPIRE APP Client ID"
$EXPIRE_secret = "your EXPIRE APP Secret"

$tenantID = "Azure Tenant ID"

#Azure App Credentials to send the Mail
$MAIL_AppId = "your Mail Client ID"
$MAIL_secret = "your Mail Secret"

#ExcludeList
$ExcludedList = "*(Power Virtual Agents);*(Microsoft Copilot Studio);RSC-CAM-Einfahrt"
$ExcludedListArray = $ExcludedList -split ";"


#STOP HERE!

#Connect to GRAPH API with EXPIRE credentials
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



#Connect to GRAPH API with MAIL Credentials
$MAIL_tokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $MAIL_AppId
    Client_Secret = $MAIL_secret
}
$MAIL_tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $MAIL_tokenBody
$MAIL_headers = @{
    "Authorization" = "Bearer $($MAIL_tokenResponse.access_token)"
    "Content-type"  = "application/json"
}


#functions
function Get-AzureResourcePaging {
    param (
        $URL,
        $AuthHeader
    )

    # List Get all Apps from Azure

    $Response = Invoke-RestMethod -Method GET -Uri $URL -Headers $AuthHeader
    $Resources = $Response.value

    $ResponseNextLink = $Response."@odata.nextLink"
    while ($ResponseNextLink -ne $null) {

        $Response = (Invoke-RestMethod -Uri $ResponseNextLink -Headers $AuthHeader -Method Get)
        $ResponseNextLink = $Response."@odata.nextLink"
        $Resources += $Response.value
    }
    return $Resources
}


#Build Array to store PSCustomObject
$Array = @()



# List Get all Apps from Azure
$URLGetApps = "https://graph.microsoft.com/v1.0/applications"
$AllApps = Get-AzureResourcePaging -URL $URLGetApps -AuthHeader $EXPIRE_headers


#Go through each App and add to our Array
foreach ($App in $AllApps) {

    $URLGetApp = "https://graph.microsoft.com/v1.0/applications/$($App.ID)"
    $App = Invoke-RestMethod -Method GET -Uri $URLGetApp -Headers $EXPIRE_headers

    if ($App.passwordCredentials) {
        foreach ($item in $App.passwordCredentials) {
            $Array += [PSCustomObject]@{
                "Type"           = "AZAPP"
                "displayName"    = $app.displayName
                "ID"             = $App.ID
                "AppID"          = $app.appId
                "SecType"        = "Secret"
                "Secret"         = $item.displayName
                "Secret-EndDate" = (Get-date $item.endDateTime)
            }
        }
    }


    if ($App.keyCredentials) {
        foreach ($item in $App.keyCredentials) {
            $Array += [PSCustomObject]@{
                'Type'           = "AZAPP"
                'displayName'    = $app.displayName
                'ID'             = $App.ID
                'AppID'          = $app.appId
                'SecType'        = "Zert"
                'Secret'         = $item.displayName
                'Secret-EndDate' = (Get-date $item.endDateTime)
            }
        }
    }
}




#Get all Service Principals
$servicePrincipals = "https://graph.microsoft.com/v1.0/servicePrincipals"
$SPList = Get-AzureResourcePaging -URL $servicePrincipals -AuthHeader $EXPIRE_headers


#Go through each SP and add to our Array
foreach ($SAML in $SPList) {
    if ($Saml.passwordCredentials) {
        foreach ($PW in $Saml.passwordCredentials) {
            $Array += [PSCustomObject]@{
                'Type'           = "SP"
                'displayName'    = $SAML.displayName
                'ID'             = $SAML.id
                'AppID'          = $Saml.appId
                'SecType'        = "Secret"
                'Secret'         = $PW.displayName
                'Secret-EndDate' = (Get-date $PW.endDateTime)
            }
        }
    }
}



$ExpireringZerts = $Array | Where-Object -Property Secret-EndDate -Value (Get-Date).AddDays($TimeSpanInDays) -lt  | Where-Object -Property Secret-EndDate -Value (Get-Date) -gt

foreach ($Zert in $ExpireringZerts) {
    $Exclude = $False
    foreach ($Entry in $ExcludedListArray) {
        if ($Zert.displayName -like $Entry) {
            $Exclude = $True
        }
    }
    if ($Exclude) {
        #do nothing
    }
    else {

        $HTML = $Zert | Convertto-HTML -Fragment -As List

        $URLsend = "https://graph.microsoft.com/v1.0/users/$MailSender/sendMail"

        $BodyJsonsend = @"
                        {
                            "message": {
                              "subject": "Azure App or SPN will expire soon $($Zert.displayName)",
                              "body": {
                                "contentType": "HTML",
                                "content": "$HTML
                                <br>
                                Michael Seidl (au2mator)
                                <br>

                                "
                              },
                              "toRecipients": [
                                {
                                  "emailAddress": {
                                    "address": "$MailRecipient"
                                  }
                                }
                              ]
                            },
                            "saveToSentItems": "false"
                          }
"@

        Invoke-RestMethod -Method POST -Uri $URLsend -Headers $MAIL_headers -Body $BodyJsonsend
    }
}