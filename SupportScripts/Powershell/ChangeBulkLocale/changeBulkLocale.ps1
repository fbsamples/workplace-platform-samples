param(
    [Parameter(Mandatory=$true, HelpMessage='Path of the user export with the list of the users you would like to change locale to')] [string]$WPExportedUsers,
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
    #Read users from XLSX file
    $global:xslxUsers = Import-Excel -Path $WPExportedUsers
    Write-Host -NoNewLine "Workplace Users File: "
    Write-Host -ForegroundColor Green "OK, Read!"
}
catch {
    #Handle exception when unable to read file
    Write-Host -ForegroundColor Red "Fatal Error when reading XLSX file. Is it the Workplace users export file?"
    exit;
}

#Init Counters
$total = 0;
$updated = 0;
$errors = 0;
$notapplicable = 0;

Foreach($u in $global:xslxUsers) {

    $uid = $u."User Id"
    $unewlocale = $u.NewLocale
    $ustatus = $u."Status".ToLower()
    $total++

    #Check if User ID and new Locale are present
    if($uid -And $unewlocale -And $ustatus) {

        $uname = $u."Full Name"
        $uactive = If($ustatus -eq "deactivated") {$false} Else {$true}

        If($Interactive.IsPresent) {
            Write-Host -NoNewLine [$uid/$uname] ->
        }

        #Craft a Body
        $body = (@{
            schemas=@("urn:ietf:params:scim:schemas:core:2.0:User");
            locale=$unewlocale;
            preferredLanguage=$unewlocale;
            id=$uid;
            active=$uactive
            } | ConvertTo-Json)

        try {
            #Update User via SCIM API
            $fbuser = Invoke-RestMethod -Method PUT -URI ("https://scim.workplace.com/Users/" + $uid) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/changeBulkLocale" -ContentType "application/json" -Body $body
            If($Interactive.IsPresent) {
                Write-Host -ForegroundColor Green " Locale changed to"$unewlocale
            }
            $updated++
        }
        catch {
            $errors++
            # Dig into the exception and print error message
            $status = $_.Exception.Response.StatusCode.value__
            $err = $_.Exception.Response.StatusCode
            $msg = $_.Exception.Message
            If($Interactive.IsPresent) {
                Write-Host -ForegroundColor Red " KO ($status): $err - $msg"
            } Else {
                Write-Host -NoNewLine [$uid/$uname] ->
                Write-Host -ForegroundColor Red " KO ($status): $err - $msg"
            }
        }
    } Else {
        $notapplicable++;
    }
}

Write-Host "---------------------------------------------------------------------------------------------------------"
Write-Host -NoNewLine -ForegroundColor Yellow "Summary "
Write-Host "- Total User: $total - Updated ($updated), Not Applicable/Found ($notapplicable), Errors ($errors)"
Write-Host "---------------------------------------------------------------------------------------------------------"
