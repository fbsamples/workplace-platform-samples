param(
    [Parameter(Mandatory=$true, HelpMessage='The ID of the post in Workplace you would like to export comments for')] [string]$PostId,
    [Parameter(Mandatory=$true, HelpMessage='The start date you would like to extract comments from. Format: DD-MM-YYYY, will default to Today')] [string]$StartDate,
    [Parameter(Mandatory=$true, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken
)

#Install ImportExcel Module
If(!(Get-module ImportExcel)){Install-Module ImportExcel -scope CurrentUser}

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

#Set the date
If($StartDate) {
    try {
        $date = $StartDate.split('-')
        $global:startdate = ([System.DateTimeOffset](Get-Date -Day $date[0] -Month $date[1] -Year $date[2])).ToUnixTimeSeconds()
    }
    catch {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when reading date. Is the StartDate you passed a valid one?"
        exit;  
    }
} Else {
    $global:startdate = [int](Get-Date -UFormat %s -Millisecond 0)
}

$global:stats = @{
    total_post_comments = 0;
    total_post_replies = 0;
    total_post_shares = 0;
    total_post_seen_by = 0;
    total_post_reactions = @{
        like = 0;
        love = 0;
        haha = 0;
        wow = 0;
        sad = 0;
        angry = 0;
    };
}

#Get post stats
Write-Host "Retrieving post stats from Workplace..."
try {
    $statsURL = "https://graph.workplace.com/$PostId/?fields=seen.limit(0).summary(total_count),reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)"
    $results = Invoke-RestMethod -Uri ($statsURL) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ExportPostStats"
        if ($results) {
            $global:stats.total_post_seen_by = $results.seen.summary.total_count;
            $global:stats.total_post_reactions.like = $results.reactions_like.summary.total_count;
            $global:stats.total_post_reactions.love = $results.reactions_love.summary.total_count;
            $global:stats.total_post_reactions.haha = $results.reactions_haha.summary.total_count;
            $global:stats.total_post_reactions.wow = $results.reactions_wow.summary.total_count;
            $global:stats.total_post_reactions.sad = $results.reactions_sad.summary.total_count;
            $global:stats.total_post_reactions.angry = $results.reactions_angry.summary.total_count;
        }
} catch {
    #Handle exception when having errors from Graph API
    Write-Host -ForegroundColor Red "Fatal Error when getting post stats from API. Is the PostId you passed correct? Are API permissions correct?"
    exit;
}

#Get comments for posts
Write-Host "Retrieving comments and replies from Workplace..."
try {
    $global:comments = @()
    $next = "https://graph.workplace.com/$PostId/comments/?fields=created_time,from{name,id,email,primary_address,department},message,id,reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry),comments.limit(0).summary(total_count)&order=chronological&since=$global:startdate"
    do {
        $results = Invoke-RestMethod -Uri ($next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ExportPostStats"
        if ($results) {
            $results.data.ForEach({
                $_ | Add-Member -NotePropertyName "Interaction" -NotePropertyValue "Comment" 
                $global:comments += $_
                $global:stats.total_post_comments++
                $nextReply = "https://graph.workplace.com/" + $_.id + "/comments/?fields=created_time,from{name,id,email,primary_address,department},message,id,reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry),comments.limit(0).summary(total_count)&order=chronological"
                do {
                    $resultsReplies = Invoke-RestMethod -Uri ($nextReply) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ExportPostStats"
                    if($resultsReplies){
                        $resultsReplies.data | ForEach-Object -Process {$_ | Add-Member -NotePropertyName "Interaction" -NotePropertyValue "Comment-Reply"}
                        $global:comments += $resultsReplies.data
                        $global:stats.total_post_replies += $resultsReplies.data.count
                        if($resultsReplies.paging.cursors.after) {
                            $afterReplies = $resultsReplies.paging.cursors.after
                            $nextReply = "https://graph.workplace.com/" + $_.id + "/comments/?fields=created_time,from{name,id,email,primary_address,department},message,id,reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry),comments.limit(0).summary(total_count)&order=chronological&after=$afterReplies"
                        }
                        else {$nextReply = $null}
                    }
                    else {$nextReply = $null}
                } while($nextReply)
            })
            if($results.paging.cursors.after) {
                $after = $results.paging.cursors.after
                $next = "https://graph.workplace.com/$PostId/comments/?fields=created_time,from{name,id,email,primary_address,department},message,id,reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry),comments.limit(0).summary(total_count)&order=chronological&since=$global:startdate&after=$after"
            }
            else {$next = $null}
        }
        else {$next = $null}
    } while($next) 
} catch {
    #Handle exception when having errors from Graph API
    Write-Host -ForegroundColor Red "Fatal Error when getting post comments from API. Is the PostId you passed correct? Are API permissions correct?"
    exit;
}

#Add comments to XLSX
try {
    
    $xlsxFile = "./stats-$PostId.xlsx" 
    $reportTitle = "Post Analytics ($PostId)"

    $xlp = $global:stats | `
    Select-Object -property `
    @{N='Total Post Comments';E={$global:stats.total_post_comments}}, `
    @{N='Total Post Replies';E={$global:stats.total_post_replies}}, `
    @{N='Total Post Shares';E={$global:stats.total_post_shares}}, `
    @{N='Total Post Seen By';E={$global:stats.total_post_seen_by}} |`
    Export-Excel -Path $xlsxFile -NoNumberConversion * -WorkSheetname PostAnalytics -StartRow 1 -PassThru

    $xlp = $global:stats | `
    Select-Object -property `
    @{N='Total Post Like';E={$_.total_post_reactions.like}}, `
    @{N='Total Post Love';E={$_.total_post_reactions.love}}, `
    @{N='Total Post Haha';E={$_.total_post_reactions.haha}}, `
    @{N='Total Post Wow';E={$_.total_post_reactions.wow}}, `
    @{N='Total Post Sad';E={$_.total_post_reactions.sad}}, `
    @{N='Total Post Angry';E={$_.total_post_reactions.angry}} |`
    Export-Excel -ExcelPackage $xlp -NoNumberConversion * -WorkSheetname PostAnalytics -StartRow 4 -PassThru

    $global:comments | `
    ForEach-Object -Process {$_} | `
    Select-Object -property `
        @{N='Full Name';E={$_.from.name}}, `
        @{N='Id';E={$_.from.id}}, `
        @{N='Email';E={$_.from.email}}, `
        @{N='Location';E={$_.from.primary_address}}, `
        @{N='Department';E={$_.from.department}}, `
        @{N='Message';E={$_.message}}, `
        @{N='Interaction';E={$_.Interaction}}, `
        @{N='Likes';E={$_.reactions_like.summary.total_count}}, `
        @{N='Loves';E={$_.reactions_love.summary.total_count}}, `
        @{N='Hahas';E={$_.reactions_haha.summary.total_count}}, `
        @{N='Wows';E={$_.reactions_wow.summary.total_count}}, `
        @{N='Sads';E={$_.reactions_sad.summary.total_count}}, `
        @{N='Angrys';E={$_.reactions_angry.summary.total_count}}, `
        @{N='Date';E={$_.created_time}} |`
        Export-Excel -ExcelPackage $xlp -NoNumberConversion * -WorkSheetname PostAnalytics -StartRow 8 -Show
    
    Write-Host -NoNewLine "Analytics written to XLSX: "
    Write-Host -ForegroundColor Green "OK, Written!"
} catch {
    #Handle exception when writing to output XLSX
    Write-Host -ForegroundColor Red "Fatal Error when writing to XLSX file!"
    exit;
}