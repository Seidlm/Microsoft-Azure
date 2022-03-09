
$applicationId = 'your Application ID'
$tenantId = 'your Tenant ID'
$secret = 'your Secret'

$subscriptionId = 'your Subscription ID'


#VM Details
$RessourceGroupName = "RG_TEST_RessourceGroup"

#Location
$Location = "northeurope"


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




$URL = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$($RessourceGroupName)?api-version=$apiversion"

$bodyNewRessourceGroup = @"
    {
        "location": "$location"
    }
"@


Invoke-RestMethod -Method PUT -URI $URL -headers $headers -body $bodyNewRessourceGroup



### Get Status

do {
  $URLtoGet = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$($RessourceGroupName)?api-version=$apiversion"
  $Result = Invoke-RestMethod -Method GET -URI $URLtoGet -headers $headers
  $result.properties.provisioningState
  Start-Sleep -Seconds 5
} until ($result.properties.provisioningState -ne "Creating")


