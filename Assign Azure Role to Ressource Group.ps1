#App Permission
#RBAC Permission = Owner at subscriotion
#GRAPH API: https://docs.microsoft.com/en-us/graph/api/user-get?view=graph-rest-1.0&tabs=http

$applicationId = 'your Application ID'
$tenantId = 'your Tenant ID'
$secret = 'your Secret'

$subscriptionId = 'your Subscription ID'



#RessourceGroupName Details
$RessourceGroupName = "RG_TEST_RessourceGroup"

#Location
$Location = "northeurope"

#Role see #https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
$Role="Owner" 

#User to be granted the Role
$User="michael@techguy.at"


#API Version
$apiversion="2015-07-01"

#Microsoft Azure Rest API authentication
#https://docs.microsoft.com/en-us/rest/api/azure/

#Azure Auth
$param = @{
  Uri    = "https://login.microsoftonline.com/$tenantId/oauth2/token?api-version=$apiversion";
  Method = 'Post';
  Body   = @{ 
    grant_type    = 'client_credentials'; 
    resource      = 'https://management.core.windows.net/'; 
    client_id     = $applicationId; 
    client_secret = $secret
  }
}

$result = Invoke-RestMethod @param
$token = $result.access_token

$headers = @{
  "Authorization" = "Bearer $($token)"
  "Content-type"  = "application/json"
}


#Connect to GRAPH API
$tokenBody = @{
  Grant_Type    = "client_credentials"
  Scope         = "https://graph.microsoft.com/.default"
  Client_Id     = $applicationId
  Client_Secret = $secret
}
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $tokenBody
$GRAPHheaders = @{
  "Authorization" = "Bearer $($tokenResponse.access_token)"
  "Content-type"  = "application/json"
}





#Get Role Defintion from Azure
$URL="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$RessourceGroupName/providers/Microsoft.Authorization/roleDefinitions?`$filter=roleName eq '$Role'&api-version=$apiversion"
$Roles=Invoke-RestMethod -Method GET -Uri $URL -Headers $headers


#Get User ID
$URLMember = "https://graph.microsoft.com/v1.0/users/$User"
$ResultMember = Invoke-RestMethod -Headers $GRAPHheaders -Uri $URLMember -Method Get


#New Guid for Role Assignment
$GUID=New-Guid

#Assigne Role
$URL = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$RessourceGroupName/providers/Microsoft.Authorization/roleAssignments/$($GUID)?api-version=$apiversion"
$bodyRole = @"
    { "properties": {
        "roleDefinitionId":"$($roles.value.id)",
        "principalId":"$($ResultMember.id)"
    }
    }
"@

Invoke-RestMethod -Method PUT -URI $URL -headers $headers -body $bodyRole
