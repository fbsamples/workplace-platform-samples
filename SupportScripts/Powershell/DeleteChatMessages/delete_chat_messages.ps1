param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken,
    [Parameter(Mandatory=$true, Position=1, HelpMessage='Use ID of message sender or receiver:')] [string]$WPUser,
    [Parameter(Mandatory=$true, Position=2, HelpMessage='Message content to look for:')] [string]$MessageContent
)

#Read JSON Access Token
try {
    $global:token = (Get-Content $WPAccessToken | Out-String | ConvertFrom-Json -ErrorAction Stop).accessToken
    Write-Host -NoNewLine "Access Token JSON File: "
    Write-Host -ForegroundColor Green "OK, Read!"
}
catch {
    #Handle exception when passed file is not JSON
    Write-Host -ForegroundColor Red "Fatal Error when reading JSON file. Is it correctly formatted? {'accessToken' : 123xyz}"
    exit;
}

Write-Host -ForegroundColor Magenta "Searching for messages containing: "$MessageContent

$user_messages_url= "https://graph.facebook.com/"+$WPUser+"/conversations?fields=messages{message,from,to}"
$messages_results = Invoke-RestMethod -Uri ($user_messages_url) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DeleteSelectedMessages"
$runonce = 1
while(($messages_results.paging.next) -or ($runonce)){
    $string_found = 0
    foreach($message in $messages_results.data.messages.data){
        $message_content = $message.message
        $message_id = $message.id
        $message_sender= $message.from.id
        $sender_email = $message.from.email
        #if($null -eq $sender_email){$sender_email ="Bot/Custom Integration-->"+$message.from.name}
        #if ($message_content -match $MessageContent){
        if (($message_content -match $MessageContent) -and ($sender_email.length -ne 0)){ #filter out messages from bots
            $string_found = 1
            do {
            Write-Host -NoNewLine -ForegroundColor Yellow "Found message: "
            Write-Host -NoNewLine -ForegroundColor White $message_content
            Write-Host -NoNewLine -ForegroundColor Yellow " sent by: "
            Write-Host -ForegroundColor White $sender_email
            Write-Host -ForegroundColor Red "  *  Delete message? (Press D/d to Delete it, [Enter] to Skip): "
            $askRes = Read-Host
            } while (!(($askRes -eq "") -Or ($askRes -eq "D") -Or ($askRes -eq "d")))

        if($askRes -eq "D" -Or $askRes -eq "d") {
            Invoke-RestMethod -Method DELETE -URI ("https://graph.facebook.com/"+$message_id+"?user="+$message_sender) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DeleteSelectedMessages"
            foreach($recipient in $message.to.data){
                #Write-Host $recipient.email
                Invoke-RestMethod -Method DELETE -URI ("https://graph.facebook.com/"+$message_id+"?user="+$recipient.id) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DeleteSelectedMessages"
            }
            Write-Host -ForegroundColor Green "  *  OK, message reviewed by user and deleted for all recipients!"
            } elseif ($askRes.length -eq 0) {
                Write-Host -ForegroundColor Green "  *  Message skipped as requested!"
            }
        }
    }
    if(!($messages_results.paging.next)){
        $runonce = 0
    }else{
        $messages_results = Invoke-RestMethod -Uri ($messages_results.paging.next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DeleteSelectedMessages"
    }
}
    if($string_found -ne 1){
        Write-Host -ForegroundColor Red "No matches found for: "$MessageContent
    }
