# Reference: https://docs.microsoft.com/en-us/graph/api/application-post-applications?view=graph-rest-1.0&tabs=http

#Application Permission:
#- Application.ReadWrite.OwnedBy
#- Application.ReadWrite.All



#Graph API Details
$MSGRAPHAPI_clientID = 'yourClientID'
$MSGRAPHAPI_tenantId = 'yourTenantID'
$MSGRAPHAPI_Clientsecret = 'yourSecret'

$MSGRAPHAPI_BaseURL = "https://graph.microsoft.com/v1.0"




#Enter Azure App Details
$AzureAppName = "TestApp1"
$AzureAppAccountType = "AzureADMyOrg" #https://docs.microsoft.com/en-us/azure/active-directory/develop/reference-app-manifest#signinaudience-attribute




#Auth MS Graph API and Get Header
$MSGRAPHAPI_tokenBody = @{  
    Grant_Type    = "client_credentials"  
    Scope         = "https://graph.microsoft.com/.default"  
    Client_Id     = $MSGRAPHAPI_clientID  
    Client_Secret = $MSGRAPHAPI_Clientsecret  
}   
$MSGRAPHAPI_tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$MSGRAPHAPI_tenantId/oauth2/v2.0/token" -Method POST -Body $MSGRAPHAPI_tokenBody  
$MSGRAPHAPI_headers = @{
    "Authorization" = "Bearer $($MSGRAPHAPI_tokenResponse.access_token)"
    "Content-type"  = "application/json"
}



#Create Azure App Reg
$CreateAzureAppReg_Body = @"
    {
        "displayName":"$AzureAppName",
        "signInAudience": "$AzureAppAccountType",
        "web": {
            "redirectUris": [],
            "homePageUrl": null,
            "logoutUrl": null,
            "implicitGrantSettings": {
                "enableIdTokenIssuance": false,
                "enableAccessTokenIssuance": false
            }
        }
    }
"@

$CreateAzureAppReg_Params = @{
    Method = "POST"
    Uri    = "$MSGRAPHAPI_BaseURL/applications"
    header = $MSGRAPHAPI_headers
    Body   = $CreateAzureAppReg_Body
}


$Result = Invoke-RestMethod @CreateAzureAppReg_Params

$Result.appId #ClientID



