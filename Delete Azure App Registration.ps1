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



#Find API ID by Name
$FindAzureAppReg_Params = @{
    Method = "GET"
    Uri    = "$MSGRAPHAPI_BaseURL/applications?`$filter=displayName eq '$AzureAppName'"
    header = $MSGRAPHAPI_headers
}

#Store App ID in the Variable
$Result = Invoke-RestMethod @FindAzureAppReg_Params



#Delete Azure App Reg
$DeleteAzureAppReg_Params = @{
    Method = "DELETE"
    Uri    = "$MSGRAPHAPI_BaseURL/applications/$($Result.value.id)"
    header = $MSGRAPHAPI_headers
}


$Result = Invoke-RestMethod @DeleteAzureAppReg_Params




