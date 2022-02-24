#Define App Reg Details
# https://docs.microsoft.com/en-us/graph/api/invitation-post?view=graph-rest-1.0&tabs=http
$clientID = "your Application ID"
$Clientsecret = "your Secret"
$tenantID = "your Tenant ID"



# Set Variables
#Guest Details
$GuestUserName = "Michael Seidl (GMAIL)"
$GuestUserMail = "seidlmichael82@gmail.com"

#Send Invitation CC to this USer
$CCRecipientName = "Michael Seidl"
$CCRecipientMail = "michael@techguy.at"

#Add Personal Text do Invite Mail
$InviteMessage = "You have been invited to join the Tenant au2mator.com"
$InviteRedirectURL="https://au2mator.com" #URL where the USer is redirected after Invite Acceptance

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

#Build Request
$URL = "https://graph.microsoft.com/v1.0/invitations"
$Method = "POST"
$body = @"
{
    "invitedUserEmailAddress":"$GuestUserMail",
    "inviteRedirectUrl":"$InviteRedirectURL",
    "invitedUserDisplayName":"$GuestUserName",
    "sendInvitationMessage": true,
    "invitedUserMessageInfo": {
        "messageLanguage": null,
        "ccRecipients": [
             {
                "emailAddress": {
                    "name": "$CCRecipientName",
                    "address": "$CCRecipientMail"
                 }
             }
        ],
        "customizedMessageBody": "$InviteMessage"
     }
}
"@

#Send Request
Invoke-RestMethod -Method $Method -Uri $URL -Body $body -Headers $headers

