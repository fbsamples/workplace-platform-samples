# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken,
    [Parameter(Mandatory=$true, Position=1, HelpMessage='Use ID of message sender:')] [string]$WPSenderUser,
    [Parameter(Mandatory=$true, Position=1, HelpMessage='Use ID of message receiver:')] [string]$WPReceiverUser

)
function CheckAccessToken
{
    #Read JSON Access Token
    try
    {
        $global:token = (Get-Content $WPAccessToken | Out-String | ConvertFrom-Json -ErrorAction Stop).accessToken
        $global:destToken = (Get-Content $WPAccessToken | Out-String | ConvertFrom-Json -ErrorAction Stop).destAccessToken
        Write-Host -NoNewLine "Access Token JSON File: "
        Write-Host -ForegroundColor Green "OK, Read!"
    }
    catch
    {
        #Handle exception when passed file is not JSON
        Write-Host -ForegroundColor Red "Fatal Error when reading JSON file. Is it correctly formatted? {'accessToken' : 123xyz}"
        exit;
    }

}

function RetrieveMessagesFromUser
{
    param (
        $WPSenderUser,
        $WPReceiverUser
    )

    try {
        Write-Host "Retrieving messages sent from user "$WPSenderUser" to user "$WPReceiverUser"..."

        $user_messages_url= "https://graph.facebook.com/"+$WPReceiverUser+"/conversations?fields=messages{message,from,to,attachments,created_time}"
        $messages_results = Invoke-RestMethod -Uri ($user_messages_url) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "GithubRep/DeleteUserMessages"
        $runonce = 1
        $message_count = 0
        $global:messages_to_delete = @{}
        while(($messages_results.paging.next) -or ($runonce)){
            foreach($message in $messages_results.data.messages.data){
                $message_content = $message.message
                $message_id = $message.id
                $message_sender= $message.from.id
                $message_receiver= $message.to.id
                $sender_email = $message.from.email
                $message_date = $message.created_time
                $message_date = $message_date -replace "T(.+)",""
                $message_attachment_type = $message.attachments.data.mime_type
                $message_attachment = $message.attachments.data.image_data.url
                if($null -eq $sender_email){$sender_email ="Bot/Custom Integration-->"+$message.from.name}
                if ($WPSenderUser -eq $message_sender) {
                    $delete_url = "https://graph.facebook.com/"+$message_id+"?user="+$WPReceiverUser
                    Write-Host $delete_url
                    $global:messages_to_delete[$message_count] = $delete_url
                    $message_count++
                }
            }
            if(!($messages_results.paging.next)){
                $runonce = 0
            }else{
                $messages_results = Invoke-RestMethod -Uri ($messages_results.paging.next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "GithubRep/DeleteUserMessages"
            }
        }
        if($message_count -le 0){
            Write-Host -ForegroundColor Red "No messages found."
        } else {
            Write-Host -ForegroundColor Green $message_count" messages found."
        }
    }
    catch
    {
        #Handle exception when retrieving messages
        Write-Host -ForegroundColor Red "Fatal Error when retrieving messages."
        $status = $_.Exception.Response.StatusCode.value__
        $msg = $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor Red $status": "$msg
        exit;
    }
}

function DeleteMessages
{
    try {
        if ($global:messages_to_delete.count -eq 0) { return }

        #Ask the user to confirm the deletion of the messages
        do {
            Write-Host -ForegroundColor Blue "Do you want to confirm the deletion of these messages? The action is not reversible (Press [Enter] to Continue, S/s to Skip): "
            $askRes = Read-Host
        } while (!(($askRes -eq "") -Or ($askRes -eq "S") -Or ($askRes -eq "s")))

        if (!$askRes -eq "") { return }
        foreach ($delete_url in $global:messages_to_delete.values) {
            Write-Host -NoNewLine $delete_url
            $result = Invoke-RestMethod -Method DELETE -URI $delete_url -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "GithubRep/DeleteUserMessages"
            if ($result.success) {
                Write-Host -ForegroundColor Green " -----> Deleted"
            } else {
                Write-Host -ForegroundColor Red " -----> NOT deleted. There was an error invoking the url to delete it."
            }
        }
    }
    catch
    {
        #Handle exception when retrieving messages
        Write-Host -ForegroundColor Red "Fatal Error when deleting messages."
        $status = $_.Exception.Response.StatusCode.value__
        $msg = $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor Red $status": "$msg
    }
}

CheckAccessToken
RetrieveMessagesFromUser -WPSenderUser $WPSenderUser -WPReceiverUser $WPReceiverUser
DeleteMessages
