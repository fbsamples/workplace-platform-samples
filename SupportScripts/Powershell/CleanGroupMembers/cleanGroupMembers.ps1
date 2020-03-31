param(
    [Parameter(Mandatory=$true, HelpMessage='The ID of the Workplace Group you would like to remove users from')] [string]$GroupId,
    [Parameter(Mandatory=$false, HelpMessage='The domain of the users you would like to remove')] [string]$EmailDomain,
    [Parameter(Mandatory=$false, HelpMessage='Path to your file listing users to remove from group')] [string]$WPGroupMembers,
    [Parameter(Mandatory=$true, HelpMessage='Path to your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken,
    [Parameter(Mandatory=$false, HelpMessage='Mode you would like to run the tool in: {Test (default), Live, Live-Force}')] [string]$Mode = 'Test'
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

#Remove users from group by using a XLSX file
if($WPGroupMembers) {
    try {
        #Install ImportExcel Module
        If(!(Get-module ImportExcel)){Install-Module ImportExcel -scope CurrentUser}
        #Read users from XLSX file
        $global:members = Import-Excel -Path $WPGroupMembers
        Write-Host -NoNewLine "Workplace Group Members File: "
        Write-Host -ForegroundColor Green "OK, Read!"
    } catch {
        #Handle exception when unable to read file	
        Write-Host -ForegroundColor Red "Fatal Error when reading XLSX file. Is it the Workplace users export file?"
        exit;
    }
#Remove users from group with a specific email domain
} elseif($EmailDomain) {
    try {    
        $global:members = @()
        #Get members of a group from API calls
        $next = "https://graph.workplace.com/$GroupId/members/?fields=name,id,email,administrator"
        do {
            #Get specific group in the community via SCIM API
            $results = Invoke-RestMethod -Uri ($next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/CleanGroupMembers"
            if ($results) {
                $global:members += $results.data
                if($results.paging.cursors.after) {
                    $after = $results.paging.cursors.after
                    $next = "https://graph.workplace.com/$GroupId/members/?fields=name,id,email,administrator&after=$after"
                }
                else {$next = $null}
            }
            else {$next = $null}
        } while($next) 
    } catch {
        #Handle exception when getting users from API throws an error
        Write-Host -ForegroundColor Red "Fatal Error when getting users via API!"
        exit;
    }
#Handle missing EmailDomain and WPGroupMembers
} else {
    #Handle exception when passed file is not JSON
    Write-Host -ForegroundColor Yellow "Missing EmailDomain or WPGroupMembers params. Please specify one."
    exit;
}

$removed = 0
$skipped = 0
$errors = 0
$hits = 0

#Remove members from a group based on params and email domain
ForEach($m in $global:members){
    #If searching by email domain and user has an email with the intended domain
    if(($EmailDomain -and $m.Email -and ($m.Email.Split('@')[1] -eq $EmailDomain)) -or ($WPGroupMembers -and ($m.Email -or $m.Id))){
        $hits++
        Write-Host -NoNewLine "[$($m.Id)/$($m.Email)]"
        if($EmailDomain) {Write-Host -ForegroundColor Green " has the $EmailDomain domain."}
        else {Write-Host -ForegroundColor Green " is marked for removal."}
        try {
            switch ($Mode) {
                #Remove member from the group but ask for removal
                'Live' {
                    #Ask the user to remove from the group
                    do {
                        Write-Host -ForegroundColor Blue -NoNewLine "  *  Confirm the removal? (Press [Enter] to Continue, S/s to Skip): "
                        $askRes = Read-Host
                    } while (!(($askRes -eq "") -Or ($askRes -eq "S") -Or ($askRes -eq "s")))
                    #Check user input response
                    if($askRes.length -eq 0) {
                        #Remove Member from Group via Graph API
                        $result = if($m.Id) {Invoke-RestMethod -Method DELETE -URI ("https://graph.workplace.com/$GroupId/members/$($m.Id)") -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/CleanGroupMembers"} 
                        else {Invoke-RestMethod -Method DELETE -URI ("https://graph.workplace.com/$GroupId/members?email=$([System.Web.HttpUtility]::UrlEncode($m.Email))") -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/CleanGroupMembers"}
                        #Check DELETE result
                        if($result.success) {
                            $removed++
                            Write-Host -ForegroundColor Green "  *  OK, change reviewed by user and done!"
                        } else {
                            $errors++
                            Write-Host -ForegroundColor Red "  *  KO, impossible to remove the users. Sure it's still in the group? User ID/Email are correct?"
                        }
                    } elseif ($askRes -eq "S" -Or $askRes -eq "s") {
                        $skipped++;
                        Write-Host -ForegroundColor Blue "  *  User skipped as requested!"
                    }
                    break
                }

                #Remove member from the group without asking for removal
                'Live-Force' { }
            }
        }
        catch {
            $errors++
            # Dig into the exception and print error message
            $status = $_.Exception.Response.StatusCode.value__
            $msg = $_.Exception.Response.StatusDescription
            Write-Host -ForegroundColor Red "  *  KO FB($status) $msg"
        }
    }
}

Write-Host "---------------------------------------------------------------------------------------------------------"
Write-Host -NoNewLine -ForegroundColor Yellow "Summary "
Write-Host "- Total User: $(($global:members.Length, $hits -ne $null)[0]) - Match: ($hits), Removed ($removed), Skipped ($skipped), Errors ($errors)"
Write-Host "---------------------------------------------------------------------------------------------------------"