#Define App Reg Details
# https://docs.microsoft.com/en-us/graph/api/invitation-post?view=graph-rest-1.0&tabs=http
$MSGRAPHAPI_clientID = 'yourClientID'
$MSGRAPHAPI_tenantId = 'yourTenantID'
$MSGRAPHAPI_Clientsecret = 'yourSecret'


$MSGRAPHAPI_BaseURL = "https://graph.microsoft.com/v1.0"

# Set Variables
#Guest Details
$NewManagerUPN = "michael.seidl@au2mator.com"
$UserUPN = "Jasmine.hofmeister@au2mator.com"



#Auth MS Graph API and Get Header
$tokenBody = @{  
    Grant_Type    = "client_credentials"  
    Scope         = "https://graph.microsoft.com/.default"  
    Client_Id     = $clientID  
    Client_Secret = $Clientsecret  
}   
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $tokenBody  
$MSGRAPHAPI_headers = @{
    "Authorization" = "Bearer $($tokenResponse.access_token)"
    "Content-type"  = "application/json"
}

#Get IDs




$GetManager_Params = @{
    Method = "GET"
    Uri    = "$MSGRAPHAPI_BaseURL/users/$NewManagerUPN"
    header = $MSGRAPHAPI_headers
}


$GetManager_Result = Invoke-RestMethod @GetManager_Params


$GetUser_Params = @{
    Method = "GET"
    Uri    = "$MSGRAPHAPI_BaseURL/users/$UserUPN"
    header = $MSGRAPHAPI_headers
}


$GetUser_Result = Invoke-RestMethod @GetUser_Params




$SetExoManager_body=@"
{
    "@odata.id": "$MSGRAPHAPI_BaseURL/users/$($GetManager_Result.id)"
}
"@

$SetExoManager_param = @{
    Method = "PUT"
    Uri    = "$MSGRAPHAPI_BaseURL/users/$($GetUser_Result.id)/manager/`$ref"
    header = $MSGRAPHAPI_headers
    body   = $SetExoManager_body
    
}

$SetExoManager_result = Invoke-RestMethod @SetExoManager_param -ContentType "application/json"