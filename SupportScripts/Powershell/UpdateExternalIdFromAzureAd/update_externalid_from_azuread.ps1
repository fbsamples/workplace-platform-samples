param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken,
	[switch]$Interactive
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
#Install AzureAD Module
If(!(Get-module AzureAD)){Install-Module AzureAD -scope CurrentUser}
try{
    Write-Host -NoNewLine "Connecting to Microsoft Azure AD... "
    connect-AzureAD
    Write-Host -ForegroundColor Green "Connected to Azure AD!"
}catch{
    #Handle exception when there is a connection issue
    Write-Host -ForegroundColor Red "Fatal Error when trying to connect to AzureAD"
    exit;
}

$aad_users = Get-AzureADUser -all $true | select UserPrincipalName, ObjectId

#Init Counters
$total = $users = (Get-AzureADUser -all $true).Count;
$user_num = 0;
$updated = 0;
$skipped = 0;
$notapplicable = 0;
$errors = 0;

Foreach($u in $aad_users) {
    $user_num++
    $uemail = $u.UserPrincipalName
    $uguid = $u.ObjectId

        try {

            #Get User via SCIM API
            $results = Invoke-RestMethod -Uri ("https://scim.workplace.com/Users/?filter=userName%20eq%20%22$uemail%22") -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/UpdateAzureExternalID"

            If($results.Resources) {

                #Get User params
                $user = $results.Resources[0]
                $uid = $user.id
                $ouname = $user.userName
                $uextid = $user.externalId
                    if($uguid -eq $uextid){
                        Write-Host -ForegroundColor Yellow "Skipped user: [$uid/$ouname] : [$uextid] -> [$uguid]"
                        $skipped++
                    }else{
                    $askRes = ""
                    If($Interactive.IsPresent) {
                        Write-Host -ForegroundColor Green "[$uid/$ouname] : [$uextid] -> [$uguid]"
                        do {
                            Write-Host -ForegroundColor Blue -NoNewLine "  *  Confirm the change? (Press [Enter] to Continue, S/s to Skip): "
                            $askRes = Read-Host
                        } while (!(($askRes -eq "") -Or ($askRes -eq "S") -Or ($askRes -eq "s")))
                    } Else {
                        Write-Host -ForegroundColor Green -NoNewLine "[$uid/$ouname] : [$uextid] -> [$uguid]: "
                    }

                    if($askRes.length -eq 0) {
                        #Craft a Body
                        $body = (@{
                        schemas=@("urn:ietf:params:scim:schemas:core:2.0:User","urn:ietf:params:scim:schemas:extension:enterprise:2.0:User","urn:ietf:params:scim:schemas:extension:facebook:starttermdates:2.0:User","urn:ietf:params:scim:schemas:extension:facebook:accountstatusdetails:2.0:User","urn:ietf:params:scim:schemas:extension:facebook:authmethod:2.0:User");
                        id=$uid;
					    externalId=$uguid;
                        active=$true
                        } | ConvertTo-Json)
					    Write-Host "$body"
                        #Update User via SCIM API
					    $user = Invoke-RestMethod -Method PUT -URI ("https://scim.workplace.com/Users" + $uid) -Headers @{Authorization = "Bearer " + $global:token} -ContentType "application/json" -Body $body -UserAgent "WorkplaceScript/UpdateAzureExternalID"
                        Write-Host "$user"
                        #Print OK message
                        if($Interactive.IsPresent) {Write-Host -ForegroundColor Green "  *  OK, change reviewed by user and done!"}
                        else {Write-Host -ForegroundColor Green "OK"}
                        $updated++
                    }elseif ($askRes -eq "S" -Or $askRes -eq "s") {
                        $skipped++;
                        Write-Host -ForegroundColor Blue "  *  User skipped as requested!"
                    }
                }

            } Else {
                Write-Host -ForegroundColor Red "[$uemail] : No user ($uemail) within your Workplace users."
                $notapplicable++;
            }
        }
        catch {
            $errors++
            # Dig into the exception and print error message
            $status = $_.Exception.Response.StatusCode.value__
            $err = $_.Exception.Response.StatusCode
			$msg = $_.Exception.Message
            If($Interactive.IsPresent) {
                Write-Host -ForegroundColor Red "  *  KO ($status): $err - $msg"
            } Else {
                Write-Host -ForegroundColor Red "KO ($status): $err - $msg"
            }
        }
        Write-Progress -Activity "Checking User ExternalID Changes" -Status "Progress:" -PercentComplete ($user_num/$total*100)

}

Write-Host "---------------------------------------------------------------------------------------------------------"
Write-Host -NoNewLine -ForegroundColor Yellow "Summary "
Write-Host "- Total User: $total - Updated ($updated), Skipped ($skipped), Not Applicable/Found ($notapplicable), Errors ($errors)"
Write-Host "---------------------------------------------------------------------------------------------------------"
