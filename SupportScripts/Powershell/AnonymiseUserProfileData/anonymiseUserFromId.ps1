# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken,
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Numeric ID for the Workplace user')] [string]$UserId
)

function CheckAccessToken
{
    #Read JSON Access Token
    try
    {
        $global:token = (Get-Content $WPAccessToken | Out-String | ConvertFrom-Json -ErrorAction Stop).accessToken
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

function AnonymiseWorkplaceUserProfile
{
    param (
        $userId
    )

    #Anonymise User Data
    Write-Host -NoNewLine "Anonymising user $userId profile data on Workplace... "
    try
    {
		$todayDate = Get-Date -Format "yyyyMMdd"
		$userDataUrl = "https://scim.workplace.com/Users/$userId"

        #Requesting data of the user to Workplace
        $results = Invoke-RestMethod -Uri ($userDataUrl) -Headers @{ Authorization = "Bearer " + $global:token } -UserAgent "GithubRep-ProfileAnonymiser"

		if ($results -and !$results.error)
        {
			#Formatting data to be sent for the anonymisation
			$emailParts = $results.userName.Split("@")
			$randomString = -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
			$newUsername = $randomString + "_" + $todayDate + "@" + $emailParts[1]
			$requestBody = '{
				"schemas" : ["urn:ietf:params:scim:schemas:core:2.0:User", "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User", "urn:scim:schemas:extension:facebook:starttermdates:1.0"],
				"userName" : "' + $newUsername + '",
				"displayName" : "Default User",
				"name" : {
					"formatted" : "Default User",
					"familyName" : "User",
					"givenName" : "Default"
				},
				"active" : ' + $results.active.ToString().ToLower() + ',
				"title" : "Default Title",
				"emails" : [{
					"primary" : false,
					"value" : "' + $newUsername + '"
				}],
				"urn:ietf:params:scim:schemas:extension:enterprise:2.0:User" : {
					"organization" : "Default Org",
					"division" : "Default Region",
					"department" : "Default Department"
				},
				"locale": "en_US",
				"preferredLanguage": "en_US",
				"addresses": [{
					"type": "work",
					"formatted": "Default Office",
					"primary": true
				}],
				"urn:scim:schemas:extension:facebook:starttermdates:1.0": {
					"startDate": 1577836800
				},
				"phoneNumbers": [{
					"primary": true,
					"type": "work",
					"value": "+1-202-555-0104"
				}],
				"photos": [{
					"value" : "https://static.xx.fbcdn.net/rsrc.php/v1/yN/r/5YNclLbSCQL.jpg",
					"type" : "profile",
					"primary" : true
				}]
			}';
			#Write-Host $requestBody
            $resultsModification = Invoke-RestMethod -Method PUT -URI ($userDataUrl) -Headers @{Authorization = "Bearer " + $global:token} -Body $requestBody -ContentType "application/json" -UserAgent "GithubRep-ProfileAnonymiser"
        }

		if ($resultsModification -and !$resultsModification.error)
        {
			Write-Host -ForegroundColor Green "Profile data from user $userId has been successfully anonymised. New data:"
			Write-Host -ForegroundColor Green $resultsModification
		} else {
			Write-Host -ForegroundColor Red "Fatal API Error when modifying user profile data."
			Write-Host -ForegroundColor Red $resultsModification.error
		}

    }
    catch
    {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when anonymising user profile data via API."
        Write-Host -ForegroundColor Red $_
    }

}

CheckAccessToken
AnonymiseWorkplaceUserProfile -userId $UserId
