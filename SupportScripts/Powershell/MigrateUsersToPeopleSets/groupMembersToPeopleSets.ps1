param(
    [Parameter(Mandatory = $true, HelpMessage = 'The ID of the group in Workplace you would like to clone FROM (Origin)')] [string]$OriginGroupId,
    [Parameter(Mandatory = $true, HelpMessage = 'Path for your Workplace access token in .json format {"accessToken" : "123xyz", "destAccessToken" : "123xyz"}')] [string]$WPAccessToken
)

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

Function ExcelToCsv($File)
{
    $myDir = Get-Location
    $excelFile = "" + $myDir + "\" + $File + ".xlsx"
    $Excel = New-Object -ComObject Excel.Application
    $wb = $Excel.Workbooks.Open($excelFile)

    foreach ($ws in $wb.Worksheets)
    {
        $ws.SaveAs("$myDir\" + $File + ".csv", 6)
    }
    $Excel.Quit()
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
        $groupUrl = "https://graph.workplace.com/" + $groupId + "?fields=name"
        Write-Host $groupUrl

        $groupMetadata = Invoke-RestMethod -Uri ($groupUrl) -Headers @{ Authorization = "Bearer " + $global:token } -UserAgent "WorkplaceScript/GroupCloner"
        $global:gMetadata = $groupMetadata

        Write-Host -ForegroundColor Green "Meta data from original group retrieved!"
    }
    catch
    {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when getting group metadata from API. Is the OriginGroupId you passed correct? Are API permissions correct?"
        Write-Host -ForegroundColor Red $_
        exit;
    }
}

Function GetGroupMembers
{
    param (
        $groupId
    )
    #Get group members
    Write-Host -NoNewLine "Retrieving group members metadata from Workplace... "
    try
    {
        $groupMembersFetchUrl = "https://graph.workplace.com/" + $groupId + "/members?fields=email,administrator&limit=20000"

        $groupMembers = Invoke-RestMethod -Uri ($groupMembersFetchUrl) -Headers @{ Authorization = "Bearer " + $global:token } -UserAgent "WorkplaceScript/GroupCloner"
        $global:gMembersdata = $groupMembers.data

        Write-Host -ForegroundColor Green "Members from original group retrieved!"
    }
    catch
    {
        #Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when getting group metadata from API. Is the OriginGroupId you passed correct? Are API permissions correct?"
        Write-Host -ForegroundColor Red $_
        exit;
    }
}

Function CreateGroupMembers
{
    #Add Members to Group
    Write-Host -NoNewLine "Creating new group members... "
    try
    {
        $CSVLocation = "" + (Get-Location) + "/" + $FileName + ".csv"
        $CSVFile = Import-Csv $CSVLocation | ConvertTo-Json | ConvertFrom-Json

        $users = "";

        for ($ib = $global:gMembersdata.count - 1; $ib -ge 0; $ib--) {
            $user = $CSVFile | Where-Object Email -contains $global:gMembersdata[$ib].email

            $userId = $user."User ID"

            $users += "{`"type`": `"user`",`"value`": `"$userId`" },"
        }

        $users = $users.Substring(0, $users.Length - 1)
        $groupName = $global:gMetadata.name

        $body = "{`"schemas`": [`"urn:scim:schemas:core:1.0`"],
                    `"displayName`": `"$groupName`",
                    `"members`": [ $users ]}"

        Invoke-WebRequest -Uri https://www.workplace.com/scim/v1/Groups -Method POST -Body $body -Headers @{ Authorization = "Bearer " + $global:destToken } -UserAgent "WorkplaceScript/GroupCloner"

        Write-Host -ForegroundColor Green "New group members added."
    }
    catch
    {
        #    Handle exception when having errors from Graph API
        Write-Host -ForegroundColor Red "Fatal Error when creating group members via API. Is the OriginGroupId you passed correct? Are API permissions correct?"
        Write-Host -ForegroundColor Red $_
        exit;
    }
}

$FileName = "users-sheet-workplace"
ExcelToCsv -File $FileName
CheckAccessToken
GetGroupMetaData -groupId $OriginGroupId
GetGroupMembers -groupId $OriginGroupId
CreateGroupMembers

