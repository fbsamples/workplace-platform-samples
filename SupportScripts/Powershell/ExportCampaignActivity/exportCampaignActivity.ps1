param(
    [Parameter(Mandatory=$true, HelpMessage='The IDs of the groups in Workplace you would like to monitor this campaign for. Format: {group-id}, {group-id}, ...')] [string[]]$GroupIds,
    [Parameter(Mandatory=$false, HelpMessage='The start date of campaign. Format: DD-MM-YYYY, will default to Today')] [string]$StartDate,
    [Parameter(Mandatory=$true, HelpMessage='The hashtags to monitor for this campaign Format: #digitaltransformation, #project2020, ...')] [string[]]$Hashtags,
    [Parameter(Mandatory=$true, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : "123xyz"}')] [string]$WPAccessToken
)

#Install ImportExcel Module
If(!(Get-module ImportExcel)){Install-Module ImportExcel -scope CurrentUser}

#API iterator function
function Iterate-On {
    Param ([String]$Url, [scriptblock]$JobItem)
    $next = $Url
    $accum = @()
    do {
        $res = Invoke-RestMethod -Uri $next -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ExportCampaignActivity"
        if($res) {
            $res.data.ForEach({
                $accum += $($JobItem.Invoke($_));
                })
            if($res.paging.cursors.after) {$next = "$($Url)&after=$($res.paging.cursors.after)"}
            else {$next = $null}
        }
        else {$next = $null}
    } while($next)
    return $accum;
}

#Sum Comments Count
function SumComments($comment){
    return $(Iterate-On -Url "https://graph.workplace.com/$($comment.id)/comments/?fields=created_time,from{name,id,email,primary_address,department},message,id,reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(CARE).limit(0).summary(total_count).as(reactions_care),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry),comments.limit(0).summary(total_count)&order=chronological" -JobItem $function:SumReplies).count
}

#Sum Replies Count
function SumReplies($reply){
    return 1
}

# Match Hashtags
function ContainsHashtags($text){
    $ht = @()
    $Hashtags.ForEach({
        If($text -Like "*$_*"){$ht += $_}
    })
    return ($ht -Join ', ')
}

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

#Extract regexp for hashtags
$HashtagsRegexp = ("({0})" -f ($Hashtags -Join '|'))

#Set the date
If($StartDate) {
    try {
        $date = $StartDate.split('-')
        $global:startdate = Get-Date (Get-Date -Day $date[0] -Month $date[1] -Year $date[2]).ToUniversalTime() -Uformat %s -Millisecond 0
    }
    catch {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when reading date. Is the StartDate you passed a valid one?"
        exit;
    }
} Else {
    $global:startdate = [int](Get-Date -UFormat %s -Millisecond 0)
}

$global:campaignAnalytics = @();

#Iterate on groups to retrieve posts after start of campaign
foreach ($groupId in $GroupIds) {

    try {

    $groupMembersCount = $(Invoke-RestMethod -Uri "https://graph.workplace.com/$groupId/?fields=members.limit(0).summary(true)" -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ExportCampaignActivity").members.summary.total_count
    $next = "https://graph.workplace.com/$groupId/feed?fields=id,message,created_time&since=$global:startdate"
    do {

        $results = Invoke-RestMethod -Uri ($next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ExportCampaignActivity"
        if ($results) {
            $results.data.ForEach({

                #Extract posts belonging to campaigns
                if($_.message -And $_.message -Match $HashtagsRegexp) {

                    #Build analytics scaffholding
                    $campaignPostAnalytics = @{
                        id = $_.id;
                        group_id = $groupId;
                        message = $_.message;
                        hashtags = ContainsHashtags($_.message);
                        created_time = $_.created_time;
                        total_post_comments = 0;
                        total_post_replies = 0;
                        total_post_shares = 0;
                        total_post_seen_by = 0;
                        total_post_reach = 0.00;
                        total_post_reactions = @{
                            like = 0;
                            love = 0;
                            haha = 0;
                            wow = 0;
                            sad = 0;
                            angry = 0;
                            care = 0;
                        };
                    }

                    try {

                        #Extract stats
                        $statsURL = "https://graph.workplace.com/$($campaignPostAnalytics.id)/?fields=seen.limit(0).summary(total_count),reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(CARE).limit(0).summary(total_count).as(reactions_care),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry),shares"
                        $sentimentResults = Invoke-RestMethod -Uri ($statsURL) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ExportCampaignActivity"

                            if ($sentimentResults) {
                                $campaignPostAnalytics.total_post_seen_by = $sentimentResults.seen.summary.total_count;
                                $campaignPostAnalytics.total_post_shares = $sentimentResults.shares.count;
                                $campaignPostAnalytics.total_post_reactions.like = $sentimentResults.reactions_like.summary.total_count;
                                $campaignPostAnalytics.total_post_reactions.love = $sentimentResults.reactions_love.summary.total_count;
                                $campaignPostAnalytics.total_post_reactions.haha = $sentimentResults.reactions_haha.summary.total_count;
                                $campaignPostAnalytics.total_post_reactions.wow = $sentimentResults.reactions_wow.summary.total_count;
                                $campaignPostAnalytics.total_post_reactions.sad = $sentimentResults.reactions_sad.summary.total_count;
                                $campaignPostAnalytics.total_post_reactions.angry = $sentimentResults.reactions_angry.summary.total_count;
                                $campaignPostAnalytics.total_post_reactions.care = $sentimentResults.reactions_care.summary.total_count;
                            }

                            try {
                                $impressions = $(Iterate-On -Url "https://graph.workplace.com/$($campaignPostAnalytics.id)/comments/?fields=created_time,from{name,id,email,primary_address,department},message,id,reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(CARE).limit(0).summary(total_count).as(reactions_care),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry),comments.limit(0).summary(total_count)&order=chronological&since=$global:startdate" -JobItem $function:SumComments)
                                $campaignPostAnalytics.total_post_comments = $impressions.count
                                $campaignPostAnalytics.total_post_replies = ($impressions | Measure-Object -sum ).sum
                            }
                            catch {
                                Write-Host -ForegroundColor Red "Fatal Error when getting post stats from API. Is the PostId you passed correct? Are API permissions correct?"
                            }

                        $campaignPostAnalytics.total_post_reach = $campaignPostAnalytics.total_post_seen_by / $groupMembersCount

                        $global:campaignAnalytics += $campaignPostAnalytics

                }
                catch {
                    #Handle exception when having errors from Graph API
                    Write-Host -ForegroundColor Red "Fatal Error when getting post stats from API. Is the GroupId you passed correct? Are API permissions correct?"
                }
            }
            })

            if($results.paging.next) {$next = $results.paging.next}
            else {$next = $null}

        }
        else {$next = $null}
    } while ($next)

    } catch {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when getting post stats from API. Is the GroupId you passed correct? Are API permissions correct?"
    }
}

#Add comments to XLSX
try {

    $xlsxFile = "./campaign-analytics-$($Hashtags -Join '').xlsx"

    $global:campaignAnalytics | `
    ForEach-Object -Process {$_} | `
    Select-Object -property `
        @{N='Post Id';E={$_.id}}, `
        @{N='Group Id';E={$_.group_id}}, `
        @{N='Hashtags';E={$_.hashtags}}, `
        @{N='Message';E={$_.message}}, `
        @{N='Date';E={$_.created_time}}, `
        @{N='Seen by';E={$_.total_post_seen_by}}, `
        @{N='Reach';E={$_.total_post_reach}}, `
        @{N='Comments';E={$_.total_post_comments}}, `
        @{N='Replies';E={$_.total_post_replies}}, `
        @{N='Shares';E={$_.total_post_shares}}, `
        @{N='Likes';E={$_.total_post_reactions.like}}, `
        @{N='Loves';E={$_.total_post_reactions.love}}, `
        @{N='Hahas';E={$_.total_post_reactions.haha}}, `
        @{N='Wows';E={$_.total_post_reactions.wow}}, `
        @{N='Cares';E={$_.total_post_reactions.care}}, `
        @{N='Sads';E={$_.total_post_reactions.sad}}, `
        @{N='Angrys';E={$_.total_post_reactions.angry}} |`
        Export-Excel $xlsxFile -NoNumberConversion *

    Write-Host -NoNewLine "Analytics written to XLSX: "
    Write-Host -ForegroundColor Green "OK, Written!"
} catch {
    #Handle exception when writing to output XLSX
    Write-Host -ForegroundColor Red "Fatal Error when writing to XLSX file!"
    exit;
}
