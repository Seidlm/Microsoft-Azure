
$applicationId = 'your Application ID'
$tenantId = 'your Tenant ID'
$secret = 'your Secret'

$subscriptionId = 'your Subscription ID'


#VM Details
$RessourceGroupName = "RG_TEST_RessourceGroup"



#API Version
$apiversion="2021-04-01"

#Microsoft Azure Rest API authentication
#https://docs.microsoft.com/en-us/rest/api/azure/


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



#Remove RessoruceGroup
$URL = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$($RessourceGroupName)?api-version=$apiversion"
Invoke-RestMethod -Method DELETE -URI $URL -headers $headers 


