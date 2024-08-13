# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

param(
    [Parameter(Mandatory=$true, HelpMessage='Path of the user export with the list of group ids you would like to archive')] [string]$WPExportedGroupIDs,
    [Parameter(Mandatory=$true, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken,
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

#Read XLSX Export File
try {
    #Read group ids from XLSX file
    $global:xslxGroups = Import-Excel -Path $WPExportedGroupIDs
    Write-Host -NoNewLine "Workplace Group Ids File: "
    Write-Host -ForegroundColor Green "OK, Read!"
}
catch {
    #Handle exception when unable to read file
    Write-Host -ForegroundColor Red "Fatal Error when reading XLSX file. Is it correctly formatted?"
    exit;
}

#Init Counters
$total = 0;
$archived = 0;
$errors = 0;

Foreach($g in $global:xslxGroups) {

    $gid = $g."Group Id"
    $gname = $null
    $total++

    try {
        #Update User via Graph API
        $groupAPI = Invoke-RestMethod -Method GET -URI ("https://graph.workplace.com/" + $gid) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ArchiveGroupsInBulk" -ContentType "application/json" -Body $body
        $gname = $groupAPI.name
    }
    catch {

    }

    $askRes = ""
    If($Interactive.IsPresent) {
        Write-Host -NoNewLine "Archive [$gid"
        If($gname) { Write-Host -NoNewLine "/$gname" }
        Write-Host "]?"
        do {
            Write-Host -ForegroundColor Blue -NoNewLine "  *  Confirm the change? (Press [Enter] to Continue, S/s to Skip): "
            $askRes = Read-Host
        } while (!(($askRes -eq "") -Or ($askRes -eq "S") -Or ($askRes -eq "s")))
    } Else {
        Write-Host -NoNewLine "Archiving [$gid"
        If($gname) { Write-Host -NoNewLine "/$gname" }
        Write-Host -NoNewLine "]..."
    }

    if($askRes.length -eq 0) {

        #Craft a Body
        $body = (@{
            archive=$true
            } | ConvertTo-Json)

        try {
            #Update User via Graph API
            $archivedGroup = Invoke-RestMethod -Method POST -URI ("https://graph.workplace.com/" + $gid) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ArchiveGroupsInBulk" -ContentType "application/json" -Body $body
            If($Interactive.IsPresent) {
                Write-Host -ForegroundColor Green "  *  Archived!"
            } Else {
                Write-Host -ForegroundColor Green " Archived!"
            }
            $archived++
        }
        catch {
            $errors++
            # Dig into the exception and print error message
            If($Interactive.IsPresent) {
                Write-Host -ForegroundColor Red "  *  Fatal Error when archiving a group via API. Is the group NOT an MCG? Is the Group Id you passed correct? Are API permissions correct?"
            } Else {
                Write-Host -ForegroundColor Red "`nFatal Error when archiving a group via API. Is the group NOT an MCG? Is the Group Id you passed correct? Are API permissions correct?"
            }
            }
        }
}

Write-Host "---------------------------------------------------------------------------------------------------------"
Write-Host -NoNewLine -ForegroundColor Yellow "Summary "
Write-Host "- Total Groups to archive: $total - Archived ($archived), Errors ($errors)"
Write-Host "---------------------------------------------------------------------------------------------------------"
