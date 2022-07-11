# Reference: https://docs.microsoft.com/en-us/graph/api/application-post-owners?view=graph-rest-1.0&tabs=http

#Application Permission:
#- Application.ReadWrite.OwnedBy
#- Directory.Read.All
#- Application.ReadWrite.All



#Graph API Details
$MSGRAPHAPI_clientID = 'yourClientID'
$MSGRAPHAPI_tenantId = 'yourTenantID'
$MSGRAPHAPI_Clientsecret = 'yourSecret'

$MSGRAPHAPI_BaseURL = "https://graph.microsoft.com/v1.0"





#Enter Azure App Details
$AzureAppObjectID = "5b8d1a75-6b99-4af5-b1b7-0127b6c39304"
$NewOwnerUPN = "michael.seidl@au2mator.com"




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


#Get USer ID from UPN
$GetUserID_Params = @{
    Method = "Get"
    Uri    = "$MSGRAPHAPI_BaseURL/users/$NewOwnerUPN"
    header = $MSGRAPHAPI_headers
}


$Result = Invoke-RestMethod @GetUserID_Params

#$Result.id #UserID


#Set new Owner
$SetRegAppOwner_Body = @"
    {
        "@odata.id" : "https://graph.microsoft.com/v1.0/directoryObjects/$($Result.id)"
    }
"@


$SetRegAppOwner_Params = @{
    Method = "POST"
    Uri    = "$MSGRAPHAPI_BaseURL/applications/$AzureAppObjectID/owners/`$ref"
    header = $MSGRAPHAPI_headers
    body = $SetRegAppOwner_Body
}


Invoke-RestMethod @SetRegAppOwner_Params


