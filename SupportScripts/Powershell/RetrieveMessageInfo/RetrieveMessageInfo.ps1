param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken,
    [Parameter(Mandatory=$true, Position=1, HelpMessage='Use ID of message sender or receiver:')] [string]$WPUser,
    [Parameter(Mandatory=$false, Position=2, HelpMessage='Message content to look for:')] [string]$MessageContent,
    [Parameter(Mandatory=$false, Position=3, HelpMessage='Search by date (format YYYY-MM-DD):')] [string]$MessageDate
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

if($MessageContent){Write-Host "Searching for messages containing: "$MessageContent}
if($MessageDate){Write-Host "Searching for messages sent on: "$MessageDate}
if(($MessageContent -eq "") -and($MessageDate -eq "")){Write-Host -ForegroundColor Red "Please search either by message content or message date"}

$user_messages_url= "https://graph.facebook.com/"+$WPUser+"/conversations?fields=messages{message,from,to,attachments,created_time}"
$messages_results = Invoke-RestMethod -Uri ($user_messages_url) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/RetrieveMessageInfo"
$runonce = 1
while(($messages_results.paging.next) -or ($runonce)){
    $string_found = 0
    foreach($message in $messages_results.data.messages.data){
        $message_content = $message.message
        $message_id = $message.id
        $message_sender= $message.from.id
        $sender_email = $message.from.email
        $message_date = $message.created_time
        $message_date = $message_date -replace "T(.+)",""
        $message_attachment_type = $message.attachments.data.mime_type
        $message_attachment = $message.attachments.data.image_data.url
        if($null -eq $sender_email){$sender_email ="Bot/Custom Integration-->"+$message.from.name}
        if ((($MessageContent -ne "") -and ($message_content -match $MessageContent)) -or (($MessageDate -ne "") -and ($message_date -match $MessageDate))){
            $string_found = 1
            do {
            Write-Host -NoNewLine -ForegroundColor Yellow "Found message: "
            if($message_content){Write-Host -NoNewLine -ForegroundColor White $message_content}else{Write-Host -NoNewline -ForegroundColor White $message_attachment_type}
            Write-Host -NoNewLine -ForegroundColor Yellow " sent by: "
            Write-Host -ForegroundColor White $sender_email
            Write-Host -NoNewLine -ForegroundColor Yellow " on date: "
            Write-Host -ForegroundColor White $message_date
            if($message_attachment){
                Write-Host -NoNewLine -ForegroundColor Yellow "Attached picture/gif: "
                Write-Host -ForegroundColor White $message_attachment
            }
            Write-Host -ForegroundColor Red "  *  Is this the correct message? (Press S/s to Select, [Enter] to Skip): "
            $askRes = Read-Host
            } while (!(($askRes -eq "") -Or ($askRes -eq "S") -Or ($askRes -eq "s")))
        if($askRes -eq "S" -Or $askRes -eq "s") {
            Write-Host -ForegroundColor Red "Message Urls:"
            $delete_url = "https://graph.facebook.com/"+$message_id+"?user="+$message_sender
            Write-Host $delete_url
            foreach($recipient in $message.to.data){
                $delete_url = "https://graph.facebook.com/"+$message_id+"?user="+$recipient.id
                Write-Host $delete_url
            }
            Write-Host -ForegroundColor Green "  *  OK, message reviewed by user and info provided!"
            } elseif ($askRes.length -eq 0) {
                Write-Host -ForegroundColor Green "  *  Message skipped as requested!"
            }
        }
    }
    if(!($messages_results.paging.next)){
        $runonce = 0
    }else{
        $messages_results = Invoke-RestMethod -Uri ($messages_results.paging.next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/RetrieveMessageInfo"
    }
}
    if($string_found -ne 1){
        Write-Host -ForegroundColor Red "No matches found."
    }