param(
    [Parameter(Mandatory=$true, HelpMessage='The ID of the group in Workplace you would like to clone FROM (Origin)')] [string]$OriginGroupId,
    [Parameter(Mandatory=$true, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken
)

function CheckAccessToken {

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

}

function GetCommentsFromPost {
	param (
        $postId
    )
	
	#Get comments for posts
	try {
		$global:posts[$global:posts.count-1].comments = @()
		
		$nextC = "https://graph.workplace.com/" + $postId + "/comments/?fields=created_time,from,message,id&order=chronological"
		do {
			$resultsC = Invoke-RestMethod -Uri ($nextC) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/GroupCloner"
			if ($resultsC) {
				$resultsC.data.ForEach({
					$_ | Add-Member -NotePropertyName "Interaction" -NotePropertyValue "Comment" 
					$_ | Add-Member -NotePropertyName "fromName" -NotePropertyValue $_.from.name
					$global:posts[$global:posts.count-1].comments += $_
					$nextReply = "https://graph.workplace.com/" + $_.id + "/comments/?fields=created_time,from,message,id&order=chronological"
					do {
						$resultsReplies = Invoke-RestMethod -Uri ($nextReply) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/GroupCloner"
						if($resultsReplies){
							$resultsReplies.data | ForEach-Object -Process {$_ | Add-Member -NotePropertyName "Interaction" -NotePropertyValue "Comment-Reply"}
							$resultsReplies.data | Add-Member -NotePropertyName "fromName" -NotePropertyValue $resultsReplies.data.from.name
							$global:posts[$global:posts.count-1].comments += $resultsReplies.data
							if($resultsReplies.paging -And $resultsReplies.paging.next) {$nextReply = $resultsReplies.paging.next}
							else {$nextReply = $null}
						}
						else {$nextReply = $null}
					} while($nextReply)
				})
				if($resultsC.paging -And $resultsC.paging.next) {$nextC = $resultsC.paging.next}
				else {$nextC = $null}
			}
			else {$nextC = $null}
		} while($nextC) 
	} catch {
		#Handle exception when having errors from Graph API
		Write-Host -ForegroundColor Red "Fatal Error when getting post comments from API. Is the PostId you passed correct? Are API permissions correct?"
		Write-Host -ForegroundColor Red $_
		exit;
	}

}

function GetGroupMetaData {
	param (
        $groupId
    )
	
	#Get group posts
	Write-Host -NoNewLine "Retrieving group metadata from Workplace... "
	try {
		$groupUrl = "https://graph.workplace.com/" + $groupId + "?fields=name,description,privacy"
		Write-Host $groupUrl
		
		$groupMetadata = Invoke-RestMethod -Uri ($groupUrl) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/GroupCloner"
		$global:gMetadata = $groupMetadata
		
		Write-Host -ForegroundColor Green "Meta data from original group retrieved!"
	} catch {
		#Handle exception when having errors from Graph API
		Write-Host -ForegroundColor Red "Fatal Error when getting group metadata from API. Is the OriginGroupId you passed correct? Are API permissions correct?"
		Write-Host -ForegroundColor Red $_
		exit;
	}

}

function GetGroupPosts {
	param (
        $groupId
    )
	
	#Get group posts
	Write-Host -NoNewLine "Retrieving group posts from Workplace... "
	try {
		$global:posts = @()
		$next = "https://graph.workplace.com/$groupId/feed?fields=id,from{name},updated_time,comments{summary},attachments,type,message,source,story,properties,permalink_url&order=chronological"
		do {
			#Write-Host $next
			$results = Invoke-RestMethod -Uri ($next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/GroupCloner"
			if ($results -and !$results.error) {
				$results.data.ForEach({
					$parentPostId = $_.id
					$_ | Add-Member -NotePropertyName "fromName" -NotePropertyValue $_.from.name
					$global:posts += $_
					#Write-Host $parentPostId
					
					if ($_.comments) {
						GetCommentsFromPost -postId $parentPostId
					}
					
				})
				if($results.paging -And $results.paging.next) {$next = $results.paging.next}
				else {$next = $null}
			}
			else {$next = $null}
		} while($next) 
		
		Write-Host -ForegroundColor Green "Posts & Comments from groups retrieved"

	} catch {
		#Handle exception when having errors from Graph API
		Write-Host -ForegroundColor Red "Fatal Error when getting group posts from API. Is the OriginGroupId you passed correct? Are API permissions correct?"
		Write-Host -ForegroundColor Red $_
		exit;
	}

}

function CreateGroupFromMetadata {
	
	#Create Group
	Write-Host -NoNewLine "Creating new group from metadata... "
	try {
		$groupUrl = "https://graph.workplace.com/community/groups?name="+ $global:gMetadata.name +"&description="+ $global:gMetadata.description +"&privacy="+ $global:gMetadata.privacy
		$groupUrl = $groupUrl -replace "\s+", "+"
		Write-Host $groupUrl
		
		$newGroup = Invoke-RestMethod -Method 'Post' -Uri ($groupUrl) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/GroupCloner"
		#$newGroup | Write-Host
		$global:newGroupId = $newGroup.id
		
		Write-Host -ForegroundColor Green "New group created. ID: $global:newGroupId"

	} catch {
		#Handle exception when having errors from Graph API
		Write-Host -ForegroundColor Red "Fatal Error when creating group via API. Is the OriginGroupId you passed correct? Are API permissions correct?"
		Write-Host -ForegroundColor Red $_
		exit;
	}

}

function CreateNewGroupPosts {
	#Create New Group Post
	Write-Host -NoNewLine "Creating new group posts... "
	try {
		for ($ia=$global:posts.count-1; $ia -ge 0; $ia--) {
			
			$postToAdd = $global:posts[$ia]
			
			#$postToAdd | Write-Host
			
			$groupUrl = "https://graph.workplace.com/" + $global:newGroupId + "/feed?formatting=MARKDOWN&message=*(Post created by " + $postToAdd.fromName + ")*" + "`n";
			if ($postToAdd.message) {$groupUrl += $postToAdd.message }
			else {
				if ($postToAdd.story) {$groupUrl += $postToAdd.story }
			}
			
			if ($postToAdd.type -eq "photo") {		
				$photoUploadURL = "https://graph.facebook.com/me/photos?published=false&url=" + [System.Web.HTTPUtility]::UrlEncode($postToAdd.attachments.data.media.image.src)
								
				$newPhotoUpload = Invoke-RestMethod -Method 'Post' -Uri ($photoUploadURL) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/GroupCloner"
				
				$groupUrl += "&attached_media=[{'media_fbid':'" + $newPhotoUpload.id + "'}]"
			}
			
			if ($postToAdd.type -eq "video") {
				$groupUrl = "https://graph.facebook.com/" + $global:newGroupId + "/videos?description=" + $postToAdd.message + " (" + $postToAdd.story + ") " + "&file_url=" + [System.Web.HTTPUtility]::UrlEncode($postToAdd.source)
			}
			
			#$groupUrl = $groupUrl -replace "\s+", "+"
			#Write-Host $groupUrl
						
			$newPost = Invoke-RestMethod -Method 'Post' -Uri ($groupUrl) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/GroupCloner"
			
			for ($ic=$postToAdd.comments.count-1; $ic -ge 0; $ic--) {
				$commentUrl = "https://graph.workplace.com/" + $newPost.id + "/comments?message=(Comment created by " + $postToAdd.comments[$ic].fromName + ")" + "`n" + $postToAdd.comments[$ic].message
				$newPost = Invoke-RestMethod -Method 'Post' -Uri ($commentUrl) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/GroupCloner"
			}
			
			#$newGroup | Write-Host
			#$global:newGroupId = $newGroup.id
			#exit;
		
		}
		
		Write-Host -ForegroundColor Green "New group posts + comments created!"

	} catch {
		#Handle exception when having errors from Graph API
		Write-Host -ForegroundColor Red "Fatal Error when creating post via API. Is the OriginGroupId you passed correct? Are API permissions correct?"
		Write-Host -ForegroundColor Red $_
		exit;
	}
}


CheckAccessToken 
GetGroupMetaData -groupId $OriginGroupId
CreateGroupFromMetadata
GetGroupPosts -groupId $OriginGroupId
CreateNewGroupPosts




