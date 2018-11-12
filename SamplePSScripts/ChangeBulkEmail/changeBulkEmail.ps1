param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Path for your Workplace export file')] [string]$WPExportedUsers,
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
$skipped = 0;
$notapplicable = 0;
$errors = 0;

Foreach($u in $global:xslxUsers) {

    #Get User Email from XLSX
    $uemail = $u.Email
    $unewemail = $u.NewEmail
    $total++

    #Check if is a standard email user and if email should be changed
    if($uemail -And $unewemail) {

        try {

            #Get User via SCIM API
            $results = Invoke-RestMethod -Uri ("https://www.facebook.com/scim/v1/Users/?filter=userName%20eq%20%22$uemail%22") -Headers @{Authorization = "Bearer " + $global:token}

            If($results.Resources) {

                #Get User params
                $user = $results.Resources[0]
                $uid = $user.id
                $ouname = $user.userName

                $askRes = ""
                If($Interactive.IsPresent) {
                    Write-Host "[$uid/$ouname] -> [$unewemail]"
                    do {
                        Write-Host -ForegroundColor Blue -NoNewLine "  *  Confirm the change? (Press [Enter] to Continue, S/s to Skip): "
                        $askRes = Read-Host
                    } while (!(($askRes -eq "") -Or ($askRes -eq "S") -Or ($askRes -eq "s")))
                } Else {
                    Write-Host -NoNewLine "[$uid/$ouname] -> [$unewemail]: "
                }

                if($askRes.length -eq 0) {

                    #Craft a Body
                    $body = (@{
                    schemas=@("urn:scim:schemas:core:1.0","urn:scim:schemas:extension:enterprise:1.0","urn:scim:schemas:extension:facebook:starttermdates:1.0","urn:scim:schemas:extension:facebook:accountstatusdetails:1.0","urn:scim:schemas:extension:facebook:auth_method:1.0");
                    id=$uid;
                    userName=$unewemail;
                    active=$true
                    } | ConvertTo-Json)

                    #Update User via SCIM API
                    $user = Invoke-RestMethod -Method PUT -URI ("https://www.facebook.com/scim/v1/Users/" + $uid) -Headers @{Authorization = "Bearer " + $global:token} -ContentType "application/json" -Body $body

                    #Print OK message
                    If($Interactive.IsPresent) {Write-Host -ForegroundColor Green "  *  OK, change reviewed by user and done!"}
                    Else {Write-Host -ForegroundColor Green "OK"}
                    $updated++

                } elseif ($askRes -eq "S" -Or $askRes -eq "s") {
                    $skipped++;
                    Write-Host -ForegroundColor Blue "  *  User skipped as requested!"
                }

            } Else {
                Write-Host -ForegroundColor Red "[$uemail] -> [$unewemail]: No user ($uemail) within your Workplace users."
                $notapplicable++;
            }
        }
        catch {
            $errors++
            # Dig into the exception and print error message
            $status = $_.Exception.Response.StatusCode.value__
            $err = $_.Exception.Response.StatusCode
            $msg = ($_.ErrorDetails.Message | ConvertFrom-Json).Errors[0].description
            If($Interactive.IsPresent) {
                Write-Host -ForegroundColor Red "  *  KO ($status): $err - $msg"
            } Else {
                Write-Host -ForegroundColor Red "KO ($status): $err - $msg"
            }
        }
    } Else {
        $notapplicable++
    }
}

Write-Host "---------------------------------------------------------------------------------------------------------"
Write-Host -NoNewLine -ForegroundColor Yellow "Summary "
Write-Host "- Total User: $total - Updated ($updated), Skipped ($skipped), Not Applicable/Found ($notapplicable), Errors ($errors)"
Write-Host "---------------------------------------------------------------------------------------------------------"