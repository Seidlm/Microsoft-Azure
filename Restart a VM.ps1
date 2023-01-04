#Microsoft Azure Rest API authentication
# https://docs.microsoft.com/en-us/rest/api/azure/
# https://learn.microsoft.com/en-us/rest/api/compute/virtual-machines/get?tabs=HTTP

#read BlogPost for Details: https://www.techguy.at/control-azure-vm-with-powershell-and-azure-rest-api

$applicationId = 'Your Client ID'
$tenantId = 'Your Tenant ID'
$secret = 'Your Secret'
$subscriptionId = 'your Subscription'


#VM Details
$ResourceGroupName = "INSTTEST46-3_group"
$VMname = "INSTTEST47-2"

#API Version
$apiversion="2022-08-01"


#Authentication
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

#Script

$URL_Action = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines/$($VMname)/restart?api-version=$apiversion"
$Return=Invoke-RestMethod -Method POST -URI $URL_Action -headers $headers


### Get Status

do {
    $URL_Status="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines/$($VMname)?api-version=$apiversion"
    $Result=invoke-RestMethod -Method GET -URI $URL_Status -headers $headers

    $result.properties.provisioningState
    Start-Sleep -Seconds 5
} until ($result.properties.provisioningState -eq "Succeeded")


