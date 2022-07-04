#App Permission
#RBAC Permission = Owner at subscriotion
#GRAPH API: https://docs.microsoft.com/en-us/graph/api/user-get?view=graph-rest-1.0&tabs=http

$applicationId = 'your Application ID'
$tenantId = 'your Tenant ID'
$secret = 'your Secret'

$subscriptionId = 'your Subscription ID'



#RessourceGroupName Details
$RessourceGroupName = "RG_TEST_RessourceGroup"

#Role see #https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
$Role = "Owner" 

#User to be granted the Role
$User = "michael@techguy.at"

#API Version
$apiversion = "2015-07-01"

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
$URL = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$RessourceGroupName/providers/Microsoft.Authorization/roleDefinitions?`$filter=roleName eq '$Role'&api-version=$apiversion"
$Roles = Invoke-RestMethod -Method GET -Uri $URL -Headers $headers


#Get User ID
$URLMember = "https://graph.microsoft.com/v1.0/users/$User"
$ResultMember = Invoke-RestMethod -Headers $GRAPHheaders -Uri $URLMember -Method Get


###Get all Role Assignment for that Ressource Group and User
$URL = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$RessourceGroupName/providers/Microsoft.Authorization/roleAssignments?`$filter=principalId eq '$($ResultMember.id)'&api-version=$apiversion"
$Assignments = Invoke-RestMethod -Method GET -URI $URL -headers $headers 

foreach ($Assignment in $Assignments) {
  #Check each Assignment if it fits, than delete
  if ($Assignment.value.properties.roleDefinitionId -eq $($roles.value.id)) {

    $URL = "https://management.azure.com$($Assignment.value.id)?api-version=$apiversion"
    Invoke-RestMethod -Method DELETE -URI $URL -headers $headers 
  }
}