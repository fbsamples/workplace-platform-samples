param(
    [Parameter(Mandatory=$true, HelpMessage='The ID of the Workplace Group you would like to export feed from')] [string]$WPGroupId,
    [Parameter(Mandatory=$false, HelpMessage='Specify this date to export posts that were updated (or created) only after it. Format: DD-MM-YYYY, will default to all posts in a group (no date)')] [string]$StartDate,
    [Parameter(Mandatory=$true, Position=1, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken,
	[switch]$Interactive
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
        $global:startdate = "&since=$(Get-Date (Get-Date -Day $date[0] -Month $date[1] -Year $date[2]).ToUniversalTime() -Uformat %s -Millisecond 0)"
    }
    catch {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when reading date. Is the StartDate you passed a valid one?"
        exit;
    }
} Else {
    $global:startdate = ""
}

#Export posts
try {
    $global:posts = @()
    #Get posts of a group from API calls
    $next = "https://graph.workplace.com/$WPGroupId/feed/?fields=created_time,updated_time,from{first_name, last_name, email},to,message,attachments,story,status_type,type$global:startdate&sorting_setting=RECENT_ACTIVITY"
    do {
        #Get specific group in the community via Graph API
        $results = Invoke-RestMethod -Uri ($next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DownloadGroupFeed"
        if ($results) {

            $results.data.ForEach({
                $post_data = $_
                $PostId = $_.id

                $post_stats = @{
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
                If($Interactive.IsPresent) {
                Write-Host "Retrieving post stats from Workplace for $PostId..."
                }

                try {

                    $statsURL = "https://graph.workplace.com/$PostId/?fields=seen.limit(0).summary(total_count),reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry),comments.limit(0).summary(total_count)"
                    $results_engagement = Invoke-RestMethod -Uri ($statsURL) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/DownloadGroupFeed"
                        if ($results_engagement) {
                            $post_stats.total_post_seen_by = $results_engagement.seen.summary.total_count;
                            $post_stats.total_post_reactions.like = $results_engagement.reactions_like.summary.total_count;
                            $post_stats.total_post_reactions.love = $results_engagement.reactions_love.summary.total_count;
                            $post_stats.total_post_reactions.haha = $results_engagement.reactions_haha.summary.total_count;
                            $post_stats.total_post_reactions.wow = $results_engagement.reactions_wow.summary.total_count;
                            $post_stats.total_post_reactions.sad = $results_engagement.reactions_sad.summary.total_count;
                            $post_stats.total_post_reactions.angry = $results_engagement.reactions_angry.summary.total_count;
                            $post_stats.total_post_comments = $results_engagement.comments.summary.total_count;
                        }
                } catch {
                    #Handle exception when having errors from Graph API
                    Write-Host -ForegroundColor Red "Fatal Error when getting post stats from API. Is the PostId you passed correct? Are API permissions correct?"
                    exit;
                }

                $post_data | Add-Member -NotePropertyName "stats" -NotePropertyValue $post_stats
                $global:posts += $post_data
            })

            if($results.paging.next) {
                $after = $results.paging.next
                $next = $after
            }
            else {$next = $null}
        }
        else {$next = $null}
    } while($next)
} catch {
    #Handle exception when getting users from API throws an error
    Write-Host -ForegroundColor Red "Fatal Error when getting posts via API!"
    exit;
}

try {

    $xlsxFile = "./feed-$WPGroupId.xlsx"

    #$xlp =
    $global:posts | `
    ForEach-Object -Process {$_} | `
    Select-Object -property `
    @{N='Id';E={$_.id}}, `
    @{N='Type';E={$_.type}}, `
    @{N='Post type';E={$_.status_type}}, `
    @{N='Creation Date';E={$_.created_time}}, `
    @{N='Last Update Date';E={$_.updated_time}}, `
    @{N='Creator';E={"$($_.from.first_name) $($_.from.last_name) ($($_.from.email))"}}, `
    @{N='Story';E={$_.story}}, `
    @{N='Message';E={$_.message}}, `
    @{N='Group Name';E={"$($_.to.data | Select-Object -ExpandProperty 'name' -first 1)"}}, `
    @{N='Tags';E={"$($_.to.data | Select-Object -ExpandProperty 'name' -Skip 1)"}}, `
    @{N='Attachment (1)';E={$_.attachments.data.media.source}}, `
    @{N='Attachment (2)';E={$_.attachments.data.media.image.src}}, `
    @{N='Total Post Like';E={$_.stats.total_post_reactions.like}}, `
    @{N='Total Post Love';E={$_.stats.total_post_reactions.love}}, `
    @{N='Total Post Haha';E={$_.stats.total_post_reactions.haha}}, `
    @{N='Total Post Wow';E={$_.stats.total_post_reactions.wow}}, `
    @{N='Total Post Sad';E={$_.stats.total_post_reactions.sad}}, `
    @{N='Total Post Angry';E={$_.stats.total_post_reactions.angry}}, `
    @{N='Total Post Comments';E={$_.stats.total_post_comments}} |`
    Export-Excel -Path $xlsxFile -NoNumberConversion *

    Write-Host -NoNewLine "Analytics written to XLSX: "
    Write-Host -ForegroundColor Green "OK, Written!"
} catch {
    #Handle exception when writing to output XLSX
    Write-Host -ForegroundColor Red "Fatal Error when writing to XLSX file!"
    exit;
}
