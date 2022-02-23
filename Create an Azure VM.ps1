
$applicationId = 'your Application ID'
$tenantId = 'your Tenant ID'
$secret = 'your Secret'

$subscriptionId = 'your Subscription ID'


#VM Details
$RessourceGroupName = "RG_TEST_TechguyNewVM"
$VMname = "TESTVM"
$NetworkInterfaceName = "TESTVM-NIC"
$vmSize="Standard_D1_v2"

#Location
$Location = "northeurope"


#Image Settings
$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServer"
$sku = "2019-Datacenter"
$version = "latest"


#VM Login
$User="User"
$PW="superSa3PW!"

#API Version
$apiversion="2021-03-01"

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




$URL = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$RessourceGroupName/providers/Microsoft.Compute/virtualMachines/$($VMname)?api-version=$apiversion"

$bodyNewVMexistingNetwork = @"
    {
        "location": "$location",
        "properties": {
          "hardwareProfile": {
            "vmSize": "$VMsize"
          },
          "storageProfile": {
            "imageReference": {
              "sku": "$sku",
              "publisher": "$publisher",
              "version": "$version",
              "offer": "$offer"
            },
            "osDisk": {
              "caching": "ReadWrite",
              "managedDisk": {
                "storageAccountType": "Standard_LRS"
              },
              "name": "myVMosdisk",
              "createOption": "FromImage"
            }
          },
          "osProfile": {
            "adminUsername": "$User",
            "computerName": "$VMname",
            "adminPassword": "$PW"
          },
          "networkProfile": {
            "networkInterfaces": [
            {
                "id": "/subscriptions/$subscriptionId/resourceGroups/$RessourceGroupName/providers/Microsoft.Network/networkInterfaces/$NetworkInterfaceName",
                "properties": {
                  "primary": true
                }
              } 
              ]
            }
          }
        } 
      } 
    }
"@


Invoke-RestMethod -Method PUT -URI $URL -headers $headers -body $bodyNewVMexistingNetwork



### Get Status

do {
  $URLtoGet = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$RessourceGroupName/providers/Microsoft.Compute/virtualMachines/$($VMname)?api-version=$apiversion"
  $Result = Invoke-RestMethod -Method GET -URI $URLtoGet -headers $headers
  $result.properties.provisioningState
  Start-Sleep -Seconds 5
} until ($result.properties.provisioningState -ne "Creating")





Connect-AzAccount
Get-AzVMImagePublisher -Location $Location | Select PublisherName
Get-AzVMImageOffer -Location $Location -PublisherName $publisher | select Offer
Get-AzVMImageSku -Location $Location -PublisherName $publisher -Offer $offer | select SKUS
Get-AzVMImage -Location $Location -PublisherName $publisher -Offer $offer -Sku $sku | Select Version
##
#
#Get-AzVMImage -Location $Location -PublisherName $publisher -Offer $offer -Skus $sku -Version $version
