
$applicationId = 'your Application ID'
$tenantId = 'your Tenant ID'
$secret = 'your Secret'

$subscriptionId = 'your Subscription ID'


#Azure Automation Details
$RessourceGroupName = "RG_TEST_RessourceGroup"
$ResourceProviderNameSpace="Microsoft.Automation" #https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types
$RessourceType="automationAccounts" #https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types

$RessourceName="New-Automation-Account2" #Name of your Automation Account


#Locations
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


#Create Ressource
$URL = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$($RessourceGroupName)/providers/$ResourceProviderNameSpace/$RessourceType/$($RessourceName)?api-version=$apiversion"
$bodyNewRessourceGroup = @"
    {
      "properties": {
      "sku": {
        "name": "Free"
      }
    },
        "location": "$location",
        "name": "$RessourceName"
    }
"@

Invoke-RestMethod -Method PUT -URI $URL -headers $headers -body $bodyNewRessourceGroup
