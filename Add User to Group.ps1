# Reference: https://docs.microsoft.com/en-us/graph/api/group-post-members?view=graph-rest-1.0&tabs=http

#Application Permission:
#- GroupMember.ReadWrite.All
#- Group.ReadWrite.All
#- Directory.ReadWrite.All



#Graph API Details
$MSGRAPHAPI_clientID = 'yourClientID'
$MSGRAPHAPI_tenantId = 'yourTenantID'
$MSGRAPHAPI_Clientsecret = 'yourSecret'

$MSGRAPHAPI_BaseURL = "https://graph.microsoft.com/v1.0"




#Details
$UserUPN="michael.seidl@au2mator.com"
$AzureGroupName="Test Group"





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



# List All Groups to find ID
$GetGroupID_Params = @{
    Method = "GET"
    Uri    = "$MSGRAPHAPI_BaseURL/groups?`$filter=displayName+eq+'$AzureGroupName'"
    header = $MSGRAPHAPI_headers
}

$GetGroupID_Result=Invoke-RestMethod @GetGroupID_Params


# List All Groups to find ID
$GetUserID_Params = @{
    Method = "GET"
    Uri    = "$MSGRAPHAPI_BaseURL/users/$UserUPN"
    header = $MSGRAPHAPI_headers
}


$GetUserID_Result=Invoke-RestMethod @GetUserID_Params



# Add user to Group
$AddUserToGroup_Body = @"
    {
        "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/$($GetUserID_Result.id)"
    }
"@

$AddUserToGroup_Params = @{
    Method = "POST"
    Uri    = "$MSGRAPHAPI_BaseURL/groups/$($GetGroupID_Result.value.id)/members/`$ref"
    header = $MSGRAPHAPI_headers
    body   = $AddUserToGroup_Body
}


$AddUserToGroup_Result=Invoke-RestMethod @AddUserToGroup_Params

