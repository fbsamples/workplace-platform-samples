param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken
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

#Init Counters
$total = 0;
$updated = 0;
$skipped = 0;
$notapplicable = 0;
$errors = 0;
$user_query_limit = 1000 #default is 25
$groups_query_limit = 100 #default is 25
#Create CSV File with Header
$file = "UserID,GroupName,GroupPrivacy,GroupID" | Out-File -FilePath .\WP_Groups_Backup.csv

#Fetch Users via Graph API from Workplace
$first_users_url = "https://graph.facebook.com/company/members?fields=id&limit="+$user_query_limit
$users_results = Invoke-RestMethod -Uri ($first_users_url) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/BackupAllUsersGroups"
$users_urls = @($first_users_url)
Write-Host "Fetching users pages - this may take a bit..."
Write-Host '1 users page found!  - each page contains up to '$user_query_limit' users'
#collect all users pages in an array
while($users_results.paging.next){
    $users_urls += $users_results.paging.next
    $users_results = Invoke-RestMethod -Uri ($users_results.paging.next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/BackupAllUsersGroups"
    Write-Host $users_urls.count' users pages found! - each page contains up to '$user_query_limit' users'
}
$lusernum = 0
foreach($luser in $users_results.data.id){$lusernum++}
$estimated_users = ($user_query_limit * ($users_urls.count - 1)) + $lusernum
Write-Host '------------------------------------------------------------'
Write-Host 'Total count of users pages found: '$users_urls.count' - Total Users Count: ' $estimated_users
Write-Host '------------------------------------------------------------'
foreach($uurl in $users_urls){
    $users_results = Invoke-RestMethod -Uri ($uurl) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/BackupAllUsersGroups"
        foreach($user in $users_results.data){
            $user_id = $user.id
            $total++
                try {
                    #Get User Groups via Graph API
                    $first_group_url = "https://graph.facebook.com/"+$user_id+"/groups?limit="+$groups_query_limit
                    $group_results = Invoke-RestMethod -Uri ($first_group_url) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/BackupAllUsersGroups" 
                    $group_urls = @($first_group_url)
                    #Collect all group pages in an array
                    while($group_results.paging.next){
                        $group_urls += $group_results.paging.next
                        $group_results = Invoke-RestMethod -Uri ($group_results.paging.next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/BackupAllUsersGroups"
                    }            
                    foreach($gurl in $group_urls){
                        if(($group_results.data.id) -ne ''){
                            foreach($g in $group_results.data){
                                $file = $user_id+','+$g.name+','+$g.privacy+','+$g.id | Out-File -FilePath .\WP_Groups_Backup.csv -Append
                            }
                        }else{
                            Write-Host -ForegroundColor Yellow 'No Groups found for: '$user_id
                            $notapplicable++
                        } 
                    }
                    $updated++
                    Write-Host -ForegroundColor Green "Backed up groups for: "$user_id" Total backed up users: "$updated" out of total: "$estimated_users" Skipped: "$skipped" Errors :"$errors    
                    Write-Progress -Activity "Backing-Up User Groups" -Status "Progress:" -PercentComplete ($updated/$estimated_users*100)
                }
                catch {
                    $errors++
                    # Dig into the exception and print error message
                    $status = $_.Exception.Response.StatusCode.value__
                    $err = $_.Exception.Response.StatusCode
                    $msg = $_.Exception.Message
                    Write-Host -ForegroundColor Red "KO ($status): $err - $msg"
                } 
            }
}
Write-Host "---------------------------------------------------------------------------------------------------------"
Write-Host -NoNewLine -ForegroundColor Yellow "Summary "
Write-Host "- Total User: $total - Backed-up: ($updated), Skipped: ($skipped), Not Applicable/Found: ($notapplicable), Errors: ($errors)"
Write-Host "---------------------------------------------------------------------------------------------------------"