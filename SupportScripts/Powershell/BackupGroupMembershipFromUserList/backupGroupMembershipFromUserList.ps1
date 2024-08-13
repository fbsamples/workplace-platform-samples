# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

param(
    [Parameter(Mandatory=$true, HelpMessage='Path of the list of users (with ID or email address) from whom you want to retain and backup their group membership')] [string]$WPUserIDFile,
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

#Read XLSX Export File
try {
    #Read group ids from XLSX file
    $global:xslxUsers = Import-Excel -Path $WPUserIDFile
    Write-Host -NoNewLine "Workplace User Ids File: "
    Write-Host -ForegroundColor Green "OK, Read!"
}
catch {
    #Handle exception when unable to read file
    Write-Host -ForegroundColor Red "Fatal Error when reading XLSX file. Is it correctly formatted?"
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

Foreach($user in $global:xslxUsers) {
    $uid = $user."User Id"
    $total++
    try {
        #Get User Groups via Graph API
        $first_group_url = "https://graph.workplace.com/"+$uid+"/groups?limit="+$groups_query_limit
        $group_results = Invoke-RestMethod -Uri ($first_group_url) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/BackupGroupMembershipFromUserList"
        $group_urls = @($first_group_url)
        #Collect all group pages in an array
        while($group_results.paging.next){
            $group_urls += $group_results.paging.next
            $group_results = Invoke-RestMethod -Uri ($group_results.paging.next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/BackupGroupMembershipFromUserList"
        }
        foreach($gurl in $group_urls){
            if(($group_results.data.id) -ne ''){
                foreach($g in $group_results.data){
                    $stringToWrite = $uid.ToString()+','+$g.name+','+$g.privacy+','+$g.id
                    $file = $stringToWrite | Out-File -FilePath .\WP_Groups_Backup.csv -Append
                }
            }else{
                Write-Host -ForegroundColor Yellow 'No Groups found for: '$uid
                $notapplicable++
            }
        }
        $updated++
        Write-Host -ForegroundColor Green "Backed up groups for: "$uid" Total backed up users: "$updated" Not Applicable/Found: "$notapplicable" Errors :"$errors
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
Write-Host "---------------------------------------------------------------------------------------------------------"
Write-Host -NoNewLine -ForegroundColor Yellow "Summary "
Write-Host "- Total User: $total - Backed-up: ($updated), Not Applicable/Found: ($notapplicable), Errors: ($errors)"
Write-Host "---------------------------------------------------------------------------------------------------------"
