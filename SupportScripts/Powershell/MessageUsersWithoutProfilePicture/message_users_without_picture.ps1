param(
    [Parameter(Mandatory=$true, Position=1, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken	
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

$message_to_send = "This is an automated message - Please update your profile picture from the default one."

$user_query_limit = 1000 #default is 25
$messaged_users = 0

    #Fetch Users profile pictures via Graph API from Workplace - Page 1
    $first_users_url = "https://graph.facebook.com/company/members?fields=picture&limit="+$user_query_limit
    $users_results = Invoke-RestMethod -Uri ($first_users_url) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/UpdateProfPicture"
    foreach($user in $users_results.data){
        if($user.picture.data.is_silhouette -eq $false){
            $body = (@{
                recipient=@{
                    id=$user.id;
                };
                message=@{
                    text=$message_to_send;
                }} | ConvertTo-Json)
                Invoke-RestMethod -Method POST -URI ("https://graph.facebook.com/me/messages") -Headers @{Authorization = "Bearer " + $global:token} -Body $body -ContentType "application/json" -UserAgent "WorkplaceScript/UpdateProfPicture"
                $messaged_users++
                Write-Host -ForegroundColor Yellow "Messaged User: "$user.id
        } 
    }
    #Fetch Users profile pictures via Graph API from Workplace - Page 2+
    while($users_results.paging.next){
        $users_results = Invoke-RestMethod -Uri ($users_results.paging.next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/UpdateProfPicture"
        foreach($user in $users_results.data){
            if($user.picture.data.is_silhouette -eq $false){
                $body = (@{
                    recipient=@{
                        id=$user.id;
                    };
                    message=@{
                        text=$message_to_send;
                    }} | ConvertTo-Json)
                    Invoke-RestMethod -Method POST -URI ("https://graph.facebook.com/me/messages") -Headers @{Authorization = "Bearer " + $global:token} -Body $body -ContentType "application/json" -UserAgent "WorkplaceScript/UpdateProfPicture"
                    Write-Host -ForegroundColor Yellow "Messaged User: "$user.id
                    $messaged_users++
            } 
        }
    }
Write-Host -ForegroundColor Green "Total Messaged Users: $messaged_users - With Message: $message_to_send"