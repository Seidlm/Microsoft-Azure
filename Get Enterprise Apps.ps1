$clientID = 'yourClientID'
$tenantId = 'yourTenantID'
$Clientsecret = 'yourSecret'

$BaseURL = "https://graph.microsoft.com/v1.0"

#Enter the Timefram in Days for the Usage
$TimeFrameInDays = 30

#Build a Dateformat for the Filter
$TimeFrameDate = Get-Date -format yyyy-MM-dd  ((Get-Date).AddDays(-$TimeFrameInDays))

#Build Array to store PSCustomObject
$Array = @()

#Auth MS Graph API and Get Header
$tokenBody = @{  
    Grant_Type    = "client_credentials"  
    Scope         = "https://graph.microsoft.com/.default"  
    Client_Id     = $clientID  
    Client_Secret = $Clientsecret  
}   
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $tokenBody  
$headers = @{
    "Authorization" = "Bearer $($tokenResponse.access_token)"
    "Content-type"  = "application/json"
}

#Get all Enterprise Apps
$URLGetApplications = "$BaseURL/applications"

$Applications = Invoke-RestMethod -Method GET -Uri $URLGetApplications -Headers $headers

foreach ($App in $Applications.value) {
    #Get Sign In/Usage
    $SignIns = Invoke-RestMethod -Method GET  -Uri "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$filter=appid eq '$($App.appId)' and createdDateTime gt $TimeFrameDate" -Headers $headers
    
    Start-Sleep -Seconds 1

    #Get Owners
    $URLGetOwner = "$BaseURL/applications/$($App.id)/owners"
    $Owner = Invoke-RestMethod -Method GET -Uri $URLGetOwner -Headers $headers
    
    if ($Owner) {
        foreach ($O in $Owner.value) {

            $Array += [PSCustomObject]@{
                "App ID"           = $App.id
                "App AppID"        = $App.appId
                "App Name"         = $App.displayName
                "Owner UPN"        = $o.userprincipalname
                "Owner Name"       = $o.displayName
                "Owner ID"         = $o.id
                "Usage Count"      = ($SignIns.value ).count
            }

        }
    }
    else {
        $Array += [PSCustomObject]@{
            "App ID"           = $App.id
            "App AppID"        = $App.appId
            "App Name"         = $App.displayName
            "Owner UPN"        = "NONE"
            "Owner Name"       = "NONE"
            "Owner ID"         = "NONE"
            "Usage Count"      = ($SignIns.value ).count
        }
    }
}

$Array | Select-Object -Property "App Name", "Owner UPN", "Usage Count" | Sort-Object -Property "Usage Count" -Descending





#$URLGetUser = "$BaseURL/users/michael.seidl@au2mator.com/appRoleAssignments"
#$AppRoles = Invoke-RestMethod -Method GET -Uri $URLGetUser -Headers $headers
#$AppRoles.value | Where-Object -Property resourceDisplayName -Value "PROD-Sync Pipedrive Activites with ToDo" -eq