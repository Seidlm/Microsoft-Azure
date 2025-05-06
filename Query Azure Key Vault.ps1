<#
This is an example on using a single function to get Azure Key Vault Secrets via Azure Autoamtion in the Cloud, OnPrem or Hybrid.
All is done without a single PS Module and with the corresponding endpoints Microsoft is providing for Managed Identities and Service Principals.
Details: https://www.techguy.at/using-azure-key-vault-to-store-your-azure-automation-credentials-and-secrets/
#>



#Define a Global Variable to keep the Authentication Token fromt he Endpoint
#This is important as you might query many Secrets in a loop and you don't want to authenticate each time and hit the throttle limits of the API
$global:AZKVResponse = $null

#Define the Key Vault Name and the Environment you are running in
#This is the part of your public Azure Key Vault URL
[string]$AZKeyVaultName = "MyAZKeyVault"

#Control the Environment you are running in. This is important as the endpoints are different for Azure Arc and AzureVMs
#When you execute the Azure Automation Runbook on a Hybrid Worker or PS Script localy, use Hybrid
#When you execute the Azure Automation Runbook in the Cloud, use Cloud
[string]$AZKeyVaultEnvironment = "Hybrid" #Hybrid, Cloud

#When you are using Hybrid Environment, you need to define the environment as well. This is important as the endpoints are different for Azure Arc and AzureVMs
[string]$AZKeyVaultEnvironmentHybrid = "AzureArc" #AzureArc, AzureVM




#Function
function Get-AZKeyVaultSecret {
    param (
        [string]$KeyVaultName,
        [string]$SecretName
    )   

    $ResourceURL = "https://vault.azure.net/&api-version=2021-02-01"

    #Here we check if the global variable is set. If it is not, we authenticate and get the token from the endpoint
    if ($null -eq $global:AZKVResponse) {
        #write-au2matorLog -Type INFO -Text "Getting KeyVault Token"
        if ($AZKeyVaultEnvironment -eq "Hybrid") {
            if ($AZKeyVaultEnvironmentHybrid -eq "AzureArc") {
                $endpoint = "http://localhost:40342/metadata/identity/oauth2/token?resource=$ResourceURL" #Azure Arc
               
                try { Invoke-WebRequest -Method GET -Uri $endpoint -Headers @{Metadata = 'True' } -UseBasicParsing } 
                catch { $wwwAuthHeader = $_.Exception.Response.Headers["WWW-Authenticate"] }

                if ($wwwAuthHeader -match "Basic realm=.+") {         
                    $secretFile = ($wwwAuthHeader -split "Basic realm=")[1]     
                } 
                $secret = cat -Raw $secretFile 
                $global:AZKVResponse = [System.Text.Encoding]::Default.GetString((Invoke-WebRequest -Method GET -Uri $endpoint -Headers  @{Metadata = 'True'; Authorization = "Basic $secret" } -UseBasicParsing).RawContentStream.ToArray()) | ConvertFrom-Json
            }
            elseif ($AZKeyVaultEnvironmentHybrid -eq "AzureVM") {
                $endpoint = "http://169.254.169.254/metadata/identity/oauth2/token?resource=$ResourceURL" #AzureVM
                $global:AZKVResponse = [System.Text.Encoding]::Default.GetString((Invoke-WebRequest -Method GET -Uri $endpoint -Headers @{Metadata = 'True' } -UseBasicParsing).RawContentStream.ToArray()) | ConvertFrom-Json
            }
        }
        else {
            $global:AZKVResponse = [System.Text.Encoding]::Default.GetString((Invoke-WebRequest -UseBasicParsing -Uri "$($env:IDENTITY_ENDPOINT)?resource=$resourceURL" -Method 'GET' -Headers @{'X-IDENTITY-HEADER' = "$env:IDENTITY_HEADER"; 'Metadata' = 'True' }).RawContentStream.ToArray()) | ConvertFrom-Json
        }
    }
    else {
        #Token is already set, do nothing        
    }

    $token = $global:AZKVResponse.access_token
    $Return = Invoke-RestMethod -Uri "https://$($KeyVaultName).vault.azure.net/secrets/$($SecretName)?api-version=7.4" -Method GET -Headers @{Authorization = "Bearer $($token)" }
    return $return.value
}

#Exampl to get the Secret from the Key Vault with the Name "MySecret"
Get-AZKeyVaultSecret -KeyVaultName $AZKeyVaultName -SecretName MySecret