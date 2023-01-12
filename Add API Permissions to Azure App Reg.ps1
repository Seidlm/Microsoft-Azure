# Reference: https://docs.microsoft.com/en-us/graph/api/application-post-applications?view=graph-rest-1.0&tabs=http
# Reference: https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list?view=graph-rest-1.0&tabs=http



#Application Permission:
#- Application.ReadWrite.OwnedBy
#- Application.ReadWrite.All
#- Directory.Read.All
#- Application.Read.All



#Graph API Details
$MSGRAPHAPI_clientID = 'yourClientID'
$MSGRAPHAPI_tenantId = 'yourTenantID'
$MSGRAPHAPI_Clientsecret = 'yourSecret'
$MSGRAPHAPI_BaseURL = "https://graph.microsoft.com/v1.0"




#Enter Azure App Details
$AzureAppName = "TestApp1"
$APIName = "Microsoft Graph" #See Code Example below to get a List of AppiNames
$ApplicationPermission = @("Mail.Send", "Mail.ReadWrite")
$DelegatedPermission = @("Mail.Send", "Mail.Send.Shared")




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


#Build Array
try { [array]$ApplicationPermission = $ApplicationPermission.split(",") }
catch { [array]$ApplicationPermission = $ApplicationPermission }

try { [array]$DelegatedPermission = $DelegatedPermission.split(",") }
catch { [array]$DelegatedPermission = $DelegatedPermission }



#Get APP ID from App Name
$GetIDfromName_Params = @{
    Method = "GET"
    Uri    = "$MSGRAPHAPI_BaseURL/applications?`$filter=displayName eq '$AzureAppName'"
    header = $MSGRAPHAPI_headers
}        

$GetIDfromName_Result = Invoke-RestMethod @GetIDfromName_Params
$GetIDfromName_Result.value.id

#API ID
$GetAPIID_Params = @{
    Method = "GET"
    Uri    = "$MSGRAPHAPI_BaseURL/servicePrincipals?`$filter=displayName eq '$APIName'"
    header = $MSGRAPHAPI_headers
}       
$GetAPIID_Result = Invoke-RestMethod @GetAPIID_Params
$GetAPIID_Result.value.id


#Get API Persmission Details
$GetSPPermissions_Params = @{
    Method = "GET"
    Uri    = "$MSGRAPHAPI_BaseURL/servicePrincipals/$($GetAPIID_Result.value.id)"
    header = $MSGRAPHAPI_headers
}
$GetSPPermissions_Result = Invoke-RestMethod @GetSPPermissions_Params


#Get actual Permission
$GetIDfromName_Result = Invoke-RestMethod @GetIDfromName_Params
$CurrentPermissions = $GetIDfromName_Result.value.requiredResourceAccess.resourceAccess


#Get and Set Application Permission
foreach ($AppPerm in $ApplicationPermission) {
    #Get AppRole Object
    $appRoleObject = $GetSPPermissions_Result.appRoles | Where-Object { $_.value -eq $AppPerm }

    if ($appRoleObject) {
                   
        #Build PSOBject with New Permissions
        $item = New-Object PSObject
        $item | Add-Member -type NoteProperty -Name 'id' -Value "$($appRoleObject.id)"
        $item | Add-Member -type NoteProperty -Name 'type' -Value "Role"

        #Check to not add duplicate Permissions
        if ($Null -eq $CurrentPermissions) {
            $CurrentPermissions = @()
            $CurrentPermissions += $item

        }
        if (!($CurrentPermissions | Where-Object { $_.id -eq $($appRoleObject.id) }) ) {
            $CurrentPermissions += $item
        }      
    }
}

#Get and Set Delegated Permission
foreach ($AppPerm in $DelegatedPermission) {
    #Get AppRole Object
    $appRoleObject = $GetSPPermissions_Result.oauth2PermissionScopes | Where-Object { $_.value -eq $AppPerm }

    if ($appRoleObject) {
                   
        #Build PSOBject with New Permissions
        $item = New-Object PSObject
        $item | Add-Member -type NoteProperty -Name 'id' -Value "$($appRoleObject.id)"
        $item | Add-Member -type NoteProperty -Name 'type' -Value "Scope"

        #Check to not add duplicate Permissions
        if ($Null -eq $CurrentPermissions) {
            $CurrentPermissions = @()
            $CurrentPermissions += $item
            

        }
        if (!($CurrentPermissions | Where-Object { $_.id -eq $($appRoleObject.id) }) ) {
            $CurrentPermissions += $item
        }    
    }
}



#Build Body to add new Permissions and keep the old ones
$SetPermissions_Body = @"
 {
     "requiredResourceAccess":[
                                 {
                                 "resourceAppId":"$($GetAPIID_Result.value.appId)",
                                 "resourceAccess":  $($CurrentPermissions |ConvertTo-Json)
                                 }
                                 ]
}
"@

#Build Parameters for Invoke
$SetPermissions_Params = @{
    Method = "PATCH"
    Uri    = "$MSGRAPHAPI_BaseURL/applications/$($GetIDfromName_Result.value.id)"
    header = $MSGRAPHAPI_headers
    body   = $SetPermissions_Body
}



#Invoke
Invoke-RestMethod @SetPermissions_Params




<#
#Get all API/ServicePrinciapls to figure out correct Name

$Uri = "$MSGRAPHAPI_BaseURL/servicePrincipals"
$SPResponse = Invoke-RestMethod -Uri $uri -Headers $MSGRAPHAPI_headers -Method Get

$ServicePrincipals = $SPResponse.value 
$SPNextLink = $SPResponse."@odata.nextLink"


while ($SPNextLink -ne $null) {

    $SPResponse = (Invoke-RestMethod -Uri $SPNextLink -Headers $MSGRAPHAPI_headers -Method Get)
    $SPNextLink = $SPResponse."@odata.nextLink"
    $ServicePrincipals += $SPResponse.value

}
$ServicePrincipals.count
$ServicePrincipals | Export-Csv -Path "C:\Users\seimi\OneDrive - Seidl Michael\2-au2mator\1 - TECHGUY\GitHub\Microsoft-Azure\export.csv"
#>