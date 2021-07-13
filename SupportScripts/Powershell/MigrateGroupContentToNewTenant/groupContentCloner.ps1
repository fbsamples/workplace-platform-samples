param(
    [Parameter(Mandatory = $true, HelpMessage = 'The ID of the group in Workplace you would like to clone FROM (Origin)')] [string]$OriginGroupId,
    [Parameter(Mandatory = $true, HelpMessage = 'Path for your Workplace access token in .json format {"accessToken" : "123xyz", "destAccessToken" : "123xyz"}')] [string]$WPAccessToken
)

$ContentTypeMap = @{
    ".csv" = "text/csv";
    ".jpg" = "image/jpeg";
    ".jpeg" = "image/jpeg";
    ".png" = "image/png";
    ".tsv" = "text/tab-separated-values";
    ".docx" = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    ".pptx" = "application/vnd.openxmlformats-officedocument.presentationml.presentation";
    ".xlsx" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    ".zip" = "application/zip";
    ".rar" = "application/x-rar-compressed";
    ".mp4" = "video/mp4";
    ".pdf" = "application/pdf";
    ".doc" = "application/msword";
}

function Get-MimeType()
{
    param([parameter(Mandatory = $true, ValueFromPipeline = $true)][ValidateNotNullorEmpty()][System.IO.FileInfo]$CheckFile)
    begin {
        Add-Type -AssemblyName "System.Web"
        [System.IO.FileInfo]$check_file = $CheckFile
        [String]$mime_type = $null
    }
    process {
        if ($check_file.Exists)
        {
            $mime_type = [System.Web.MimeMapping]::GetMimeMapping($check_file.FullName)
        }
        else
        {
            $mime_type = "false"
        }
    }
    end {
        return $mime_type
    }
}

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

function GetCommentsFromPost
{
    param (
        $postId
    )

    #Get comments for posts
    try
    {
        $global:posts[$global:posts.count - 1].comments = @()

        $nextC = "https://graph.workplace.com/" + $postId + "/comments/?fields=created_time,from,message,id&order=chronological&limit=20000"
        do
        {
            $resultsC = Invoke-RestMethod -Uri ($nextC) -Headers @{ Authorization = "Bearer " + $global:token } -UserAgent "GithubRep-GroupCloner"
            if ($resultsC)
            {
                $resultsC.data.ForEach({
                    $_ | Add-Member -NotePropertyName "Interaction" -NotePropertyValue "Comment"
                    $_ | Add-Member -NotePropertyName "fromName" -NotePropertyValue $_.from.name
                    $global:posts[$global:posts.count - 1].comments += $_
                    $nextReply = "https://graph.workplace.com/" + $_.id + "/comments/?fields=created_time,from,message,id&order=chronological&limit=20000"
                    do
                    {
                        $resultsReplies = Invoke-RestMethod -Uri ($nextReply) -Headers @{ Authorization = "Bearer " + $global:token } -UserAgent "GithubRep-GroupCloner"
                        if ($resultsReplies)
                        {
                            $resultsReplies.data | ForEach-Object -Process { $_ | Add-Member -NotePropertyName "Interaction" -NotePropertyValue "Comment-Reply" }
                            $resultsReplies.data | Add-Member -NotePropertyName "fromName" -NotePropertyValue $resultsReplies.data.from.name
                            $global:posts[$global:posts.count - 1].comments += $resultsReplies.data
                            if ($resultsReplies.paging -And $resultsReplies.paging.next)
                            {
                                $nextReply = $resultsReplies.paging.next
                            }
                            else
                            {
                                $nextReply = $null
                            }
                        }
                        else
                        {
                            $nextReply = $null
                        }
                    } while ($nextReply)
                })
                if ($resultsC.paging -And $resultsC.paging.next)
                {
                    $nextC = $resultsC.paging.next
                }
                else
                {
                    $nextC = $null
                }
            }
            else
            {
                $nextC = $null
            }
        } while ($nextC)
    }
    catch
    {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when getting post comments from API. Is the PostId you passed correct? Are API permissions correct?"
        Write-Host -ForegroundColor Red $_
    }

}

function GetGroupMetaData
{
    param (
        $groupId
    )

    #Get group info
    Write-Host -NoNewLine "Retrieving group metadata from Workplace... "
    try
    {
        $groupUrl = "https://graph.workplace.com/" + $groupId + "?fields=name,description,privacy"
        Write-Host $groupUrl

        $groupMetadata = Invoke-RestMethod -Uri ($groupUrl) -Headers @{ Authorization = "Bearer " + $global:token } -UserAgent "GithubRep-GroupCloner"
        $global:gMetadata = $groupMetadata

        Write-Host -ForegroundColor Green "Meta data from original group retrieved!"
    }
    catch
    {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when getting group metadata from API. Is the OriginGroupId you passed correct? Are API permissions correct?"
        Write-Host -ForegroundColor Red $_
    }
}

function GetGroupPosts
{
    param (
        $groupId
    )

    #Get group posts
    Write-Host -NoNewLine "Retrieving group posts from Workplace... "
    try
    {
        $global:posts = @()
        $next = "https://graph.workplace.com/$groupId/feed?fields=id,from{name},updated_time,created_time,comments{summary,message,from,created_time,attachment},attachments,type,message,source,story,properties,permalink_url&order=chronological&limit=50"
        do
        {
            #Write-Host $next
            $results = Invoke-RestMethod -Uri ($next) -Headers @{ Authorization = "Bearer " + $global:token } -UserAgent "GithubRep-GroupCloner"
            if ($results -and !$results.error)
            {
                $results.data.ForEach({
                    $parentPostId = $_.id
                    $_ | Add-Member -NotePropertyName "fromName" -NotePropertyValue $_.from.name
                    $global:posts += $_
                    #Write-Host $parentPostId

                    if ($_.comments)
                    {
                        GetCommentsFromPost -postId $parentPostId
                    }

                })
                if ($results.paging -And $results.paging.next)
                {
                    $next = $results.paging.next
                }
                else
                {
                    $next = $null
                }
            }
            else
            {
                $next = $null
            }
        } while ($next)

        Write-Host -ForegroundColor Green "Posts & Comments from groups retrieved"

    }
    catch
    {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when getting group posts from API. Is the OriginGroupId you passed correct? Are API permissions correct?"
        Write-Host -ForegroundColor Red $_
    }

}

function CreateGroupFromMetadata
{

    #Create Group
    Write-Host -NoNewLine "Creating new group from metadata... "
    try
    {
        $groupUrl = "https://graph.workplace.com/community/groups?name=" + $global:gMetadata.name + "&description=" + $global:gMetadata.description + "&privacy=" + $global:gMetadata.privacy
        $groupUrl = $groupUrl -replace "\s+", "+"
        Write-Host $groupUrl

        $newGroup = Invoke-RestMethod -Method 'Post' -Uri ($groupUrl) -Headers @{ Authorization = "Bearer " + $global:destToken } -UserAgent "GithubRep-GroupCloner"
        #$newGroup | Write-Host
        $global:newGroupId = $newGroup.id

        Write-Host -ForegroundColor Green "New group created. ID: $global:newGroupId"

    }
    catch
    {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when creating group via API. Is the OriginGroupId you passed correct? Are API permissions correct?"
        Write-Host -ForegroundColor Red $_
    }
}

function CreateNewGroupPosts
{
    #Create New Group Post
    Write-Host -NoNewLine "Creating new group posts... "
    Write-Host "Posts fetched: " + $global:posts.count

    try
    {
        for ($ia = $global:posts.count - 1; $ia -ge 0; $ia--) {

            $album = 0
            $postToAdd = $global:posts[$ia]
            $dateStr = Get-Date $postToAdd.created_time -Format ("HH:mm, MMMM dd yyyy")

            #$postToAdd | Write-Host

            $groupUrl = "https://graph.workplace.com/" + $global:newGroupId + "/feed?formatting=MARKDOWN&message=*(Post created by " + $postToAdd.fromName + " - " + $dateStr + ")*" + "`n";

            Write-Host "New post started..."
            Write-Host "Post count: " + $ia

            if ($postToAdd.attachments -and $postToAdd.type -eq "status")
            {

                Write-Host "Adding post with attachments..."

                $attachments = "["
                $filesUploaded = 0
                $filesNotUploadedLinks = ""

                for ($ib = $postToAdd.attachments.data.count - 1; $ib -ge 0; $ib--) {
                    try
                    {
                        if ($postToAdd.attachments.data[$ib].type -eq "album")
                        {
                            $album = 1

                            if ($postToAdd.attachments.data[$ib].subattachments)
                            {

                                $subattachments = $postToAdd.attachments.data[$ib].subattachments.data
                                for ($ig = $subattachments.count - 1; $ig -ge 0; $ig--) {
                                    $partNo = $ig + 1
                                    $source = $subattachments[$ig].media.source

                                    $groupUrl = "https://graph.workplace.com/" + $global:newGroupId + "/videos?description=" + [System.Web.HTTPUtility]::UrlEncode("*(Post created by " + $postToAdd.fromName + " - " + $dateStr + " - Part " + $partNo + "/" + $subattachments.count + ")*" + "`n" + $postToAdd.message) + [System.Web.HTTPUtility]::UrlEncode(" (" + $postToAdd.story + ") ") + "&file_url=" + [System.Web.HTTPUtility]::UrlEncode($source)

                                    createPost -groupUrl $groupUrl -postToAdd $postToAdd
                                }
                            }
                        }
                        else
                        {
                            $title_obj = $postToAdd.attachments.data[$ib].title
                            $title = $title_obj -replace "\s[·] version \d", ""

                            try {
                                Invoke-WebRequest $postToAdd.attachments.data[$ib].url -OutFile $title

                                $FilePath = '' + (Get-Location) + '\' + $title;
                                $File = Get-ChildItem $FilePath

                                $URL = 'https://graph.workplace.com/group_file_revisions';

                                $fileBytes = [IO.File]::ReadAllBytes($FilePath)
                                $enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
                                $fileEnc = $enc.GetString($fileBytes)
                                $boundary = [System.Guid]::NewGuid().ToString()
                                $FileMimeType = $ContentTypeMap[$File.Extension.ToLower()]
                                $fileName = $title
                                $contentLength = [System.Text.Encoding]::ASCII.GetByteCount($fileBytes)

                                $LF = "`n"
                                $bodyLines = (
                                "--$boundary",
                                "Content-Disposition: form-data; name=`"file`"; filename=$fileName", # filename= is optional
                                "Content-Type: $FileMimeType$LF",
                                "Content-Length: $contentLength$LF",
                                "Transfer-Encoding: `"chunked`"$LF",
                                $fileEnc,
                                "--$boundary--$LF"
                                ) -join $LF

                                $send_file = Invoke-RestMethod -ErrorAction Stop -Uri $URL -Method Post -TimeoutSec 2147483647 -ContentType "multipart/form-data; boundary=`"$boundary`"" -Headers @{ Authorization = "Bearer " + $global:destToken } -UserAgent "GithubRep-GroupCloner" -Body $bodyLines

                                $attachments += $send_file.id + ','

                                Remove-Item $FilePath

                                $filesUploaded = 1
                            }
                            catch
                            {
                                $filesNotUploadedLinks += $postToAdd.attachments.data[$ib].url + "`n"
                                Write-Host "No file to upload:" + $postToAdd.attachments.data[$ib]
                            }
                        }
                    }
                    catch
                    {
                        $filesNotUploadedLinks += $postToAdd.attachments.data[$ib].url + "`n"
                        Write-Host -ForegroundColor Red "Could not upload file:" + $postToAdd.attachments.data[$ib]
                        Write-Host -ForegroundColor Red $_
                    }
                }

                $attachments = $attachments.Substring(0, $attachments.Length - 1) + "]"

                if ($filesUploaded)
                {
                    $groupUrl = "https://graph.workplace.com/" + $global:newGroupId + "/feed?formatting=MARKDOWN&files=" + $attachments + "&message=*(Post created by " + $postToAdd.fromName + " - " + $dateStr + ")*" + "`n";
                }
                else
                {
                    $groupUrl = "https://graph.workplace.com/" + $global:newGroupId + "/feed?formatting=MARKDOWN&message=*(Post created by " + $postToAdd.fromName + " - " + $dateStr + ")*" + "`n";
                }

                if ($filesNotUploadedLinks)
                {
                    $groupUrl += [System.Web.HTTPUtility]::UrlEncode("***Not uploaded file links:" + $filesNotUploadedLinks + "***")
                }
            }

            if ($postToAdd.message)
            {
                $groupUrl += [System.Web.HTTPUtility]::UrlEncode($postToAdd.message)
            }
            else
            {
                if ($postToAdd.story)
                {
                    $groupUrl += [System.Web.HTTPUtility]::UrlEncode($postToAdd.story)
                }
            }

            if ($postToAdd.type -eq "photo")
            {
                if ($postToAdd.attachments.data.subattachments)
                {
                    $subImages = "["

                    for ($ib = $postToAdd.attachments.data.subattachments.data.count - 1; $ib -ge 0; $ib--) {
                        try
                        {
                            Write-Host "Adding photo of album..."
                            $photoUploadURL = "https://graph.workplace.com/me/photos?published=false&url=" + [System.Web.HTTPUtility]::UrlEncode($postToAdd.attachments.data.subattachments.data[$ib].media.image.src)

                            $newPhotoUpload = Invoke-RestMethod -ErrorAction Stop -Method 'Post' -Uri ($photoUploadURL) -Headers @{ Authorization = "Bearer " + $global:destToken } -UserAgent "GithubRep-GroupCloner"

                            $subImages += "{'media_fbid':" + $newPhotoUpload.id + "},"
                        }
                        catch
                        {
                            Write-Host -ForegroundColor Red "Fatal Error when creating post via API. A photo could not be uploaded"
                            Write-Host -ForegroundColor Red $_
                        }
                    }

                    $subImages = $subImages.Substring(0, $subImages.Length - 1) + "]"

                    $groupUrl += "&attached_media=" + $subImages

                }
                else
                {
                    try
                    {
                        $photoUploadURL = "https://graph.workplace.com/me/photos?published=false&url=" + [System.Web.HTTPUtility]::UrlEncode($postToAdd.attachments.data[0].media.image.src)

                        $newPhotoUpload = Invoke-RestMethod -ErrorAction Stop -Method 'Post' -Uri ($photoUploadURL) -Headers @{ Authorization = "Bearer " + $global:destToken } -UserAgent "GithubRep-GroupCloner"

                        $groupUrl += "&attached_media=[{'media_fbid':'" + $newPhotoUpload.id + "'}]"
                    }
                    catch
                    {
                        Write-Host -ForegroundColor Red "Fatal Error when creating post via API. A photo could not be uploaded"
                        Write-Host -ForegroundColor Red $_
                    }
                }
            }

            if ($postToAdd.type -eq "video")
            {
                $groupUrl = "https://graph.workplace.com/" + $global:newGroupId + "/videos?description=" + [System.Web.HTTPUtility]::UrlEncode("*(Post created by " + $postToAdd.fromName + " - " + $dateStr + ")*" + "`n" + $postToAdd.message) + [System.Web.HTTPUtility]::UrlEncode(" (" + $postToAdd.story + ") ") + "&file_url=" + [System.Web.HTTPUtility]::UrlEncode($postToAdd.source)
            }

            #$groupUrl = $groupUrl -replace "\s+", "+"
            #Write-Host $groupUrl

            if (-Not($album))
            {
                createPost -groupUrl $groupUrl -postToAdd $postToAdd
            }

            Write-Host "Finished adding post"

            #$newGroup | Write-Host
            #$global:newGroupId = $newGroup.id
            #exit;

        }

        Write-Host -ForegroundColor Green "New group posts + comments created!"
    }
    catch
    {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when creating post via API. Is the OriginGroupId you passed correct? Are API permissions correct?"
        Write-Host -ForegroundColor Red $_
    }
}

function createPost
{
    param (
        $groupUrl,
        $postToAdd
    )

    try
    {
        Write-Host $groupUrl
        $newPost = Invoke-RestMethod -Method 'Post' -Uri ($groupUrl) -Headers @{ Authorization = "Bearer " + $global:destToken } -UserAgent "GithubRep-GroupCloner"
    }
    catch
    {
        Write-Host -ForegroundColor Red "Fatal Error when creating post via API. Is the OriginGroupId you passed correct? Are API permissions correct?"
        Write-Host -ForegroundColor Red $_
    }

    for ($ic = $postToAdd.comments.count - 1; $ic -ge 0; $ic--) {
        Write-Host "Adding new comment"

        if ($postToAdd.comments[$ic].attachment.url)
        {
            Write-Host -ForegroundColor Red "This comment has an attachment that cannot be uploaded"
            Write-Host -ForegroundColor Red "New Post ID:" + $newPost.id
            Write-Host -ForegroundColor Red "Attachment URL: " + $postToAdd.comments[$ic].attachment.url
        }

        try
        {
            $postCommentDate = Get-Date $postToAdd.comments[$ic].created_time -Format ("HH:mm, MMMM dd yyyy")
            $commentUrl = "https://graph.workplace.com/" + $newPost.id + "/comments?message=" + [System.Web.HTTPUtility]::UrlEncode("(Comment created by " + $postToAdd.comments[$ic].from.name + " - " + $postCommentDate + ")" + "`n" + $postToAdd.comments[$ic].message)
            $newComment = Invoke-RestMethod -ErrorAction Stop -Method 'Post' -Uri ($commentUrl) -Headers @{ Authorization = "Bearer " + $global:destToken } -UserAgent "GithubRep-GroupCloner"
        }
        catch
        {
            Write-Host -ForegroundColor Red "This comment could not be added"
            #            Write-Host -ForegroundColor Red "New Post ID:" + $newPost.id
        }
    }
}

CheckAccessToken
GetGroupMetaData -groupId $OriginGroupId
CreateGroupFromMetadata
GetGroupPosts -groupId $OriginGroupId
CreateNewGroupPosts
