param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken,
    [Parameter(Mandatory=$true, Position=1, HelpMessage='Start Date in format YYYY-MM-DD:')] [string]$StartDate,
    [Parameter(Mandatory=$true, Position=2, HelpMessage='End Date in format YYYY-MM-DD:')] [string]$EndDate,
    [switch]$Interactive
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

$StartDate_processed = $StartDate.Split("-")
$EndDate_processed = $EndDate.Split("-")

$StartDate_year = $StartDate_processed[0]
$StartDate_month = $StartDate_processed[1]
$StartDate_day = $StartDate_processed[2]
$EndDate_year = $EndDate_processed[0]
$EndDate_month = $EndDate_processed[1]
$EndDate_day = $EndDate_processed[2]

$user_query_limit = 1000 #default is 25
$messaged_users = 0
#Fetch Users ids via graph API
$first_users_url = "https://graph.facebook.com/company/members?fields=id&limit="+$user_query_limit
$users_results = Invoke-RestMethod -Uri ($first_users_url) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DeleteUsersPosts"
$runonce = 1
while(($users_results.paging.next) -or ($runonce)){
    #For each user check their feed
    foreach($user in $users_results.data.id){
        $feed_results= Invoke-RestMethod -Uri ("https://graph.facebook.com/"+$user+"/feed") -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DeleteUsersPosts"
        $runagain = 1
        Write-Host -ForegroundColor Yellow "Checking posts for: "$user
        while(($feed_results.paging.next) -or ($runagain)){
            foreach($post in $feed_results.data){
                #Split the date down
                $post_datetime_processed = $post.created_time.Split("T")
                $post_datetime_processed = $post_datetime_processed[0].Split("-")
                $post_year = $post_datetime_processed[0]
                $post_month = $post_datetime_processed[1]
                $post_day = $post_datetime_processed[2]
                #Check if the user post is matching the deletion criteria (date)
                if(($post_year -ge $StartDate_year) -and ($post_month -ge $StartDate_month) -and ($post_day -ge $StartDate_day) -and ($post_year -le $EndDate_year) -and ($post_month -le $EndDate_month) -and ($post_day -le $EndDate_day)){
                    #If it does, delete most matching the criteria
                    $askRes = ""
                    If($Interactive.IsPresent) {
                        do {
                            Write-Host -ForegroundColor Yellow "Delete post: "$post.id" for user "$user" ?"
                            Write-Host -ForegroundColor Yellow "Post Creation Date: "$post.created_time" with content "$post.message
                            Write-Host -ForegroundColor Blue -NoNewLine "  *  Confirm the change? (Press [Enter] to Continue, S/s to Skip): "
                            $askRes = Read-Host
                        } while (!(($askRes -eq "") -Or ($askRes -eq "S") -Or ($askRes -eq "s")))
                    } else {
                        Write-Host -ForegroundColor Yellow "Deleting post: "$post.id" for user "$user
                    }
                    if($askRes.length -eq 0) {
                        Invoke-RestMethod -Method DELETE -Uri ("https://graph.facebook.com/"+$post.id) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DeleteUsersPosts"
                        Write-Host -ForegroundColor Green "Deleted post: "$post.id" for user "$user
                    }elseif ($askRes -eq "S" -Or $askRes -eq "s") {
                        Write-Host -ForegroundColor Blue "Skipped post: "$post.id" for user "$user
                    }
                }
            }
            if(!($feed_results.paging.next)){
            $runagain = 0
            }else{
            $feed_results = Invoke-RestMethod -Uri ($feed_results.paging.next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DeleteUsersPosts"
            }
        }
    }
    if(!($users_results.paging.next)){
        $runonce = 0
    }else{
        $users_results = Invoke-RestMethod -Uri ($users_results.paging.next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DeleteUsersPosts"
    }
}
