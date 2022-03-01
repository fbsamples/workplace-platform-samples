param(
    [Parameter(Mandatory=$true, HelpMessage='The ID of the Workplace Group you would like to export')] [string]$GroupId,
    [Parameter(Mandatory=$true, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken
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

#Get specific group in the community via Graph API
try {
    $global:members = @()
    $next = "https://graph.workplace.com/$GroupId/members/?fields=name,id,email,administrator,primary_address,department"
    do {
        $results = Invoke-RestMethod -Uri ($next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ExportGroupMembers"
        if ($results) {
            $global:members += $results.data
            if($results.paging.cursors.after) {
                $after = $results.paging.cursors.after
                $next = "https://graph.workplace.com/$GroupId/members/?fields=name,id,email,administrator,primary_address,department&after=$after"
            }
            else {$next = $null}
        }
        else {$next = $null}
    } while($next)
} catch {
    #Handle exception when having errors from Graph API
    Write-Host -ForegroundColor Red "Fatal Error when getting group members from API. Is the GroupId you passed correct? Are API permissions correct?"
    exit;
}

#Add members to XLSX
try {
    #Clean email-less fields
    $global:members | Where-Object {$_.email -And $_.email.endswith("emailless.facebook.com")} | ForEach-Object {$_.email = $null}
    #Format property names
    $global:members | `
    ForEach-Object -Process {$_} | `
    Select-Object -property `
        @{N='Full Name';E={$_.name}}, `
        @{N='Id';E={$_.id}}, `
        @{N='Email';E={$_.email}}, `
        @{N='Location';E={$_.primary_address}}, `
        @{N='Department';E={$_.department}}, `
        @{N='Administrator';E={$_.Administrator}} | `
        Export-Excel "./members-$GroupId.xlsx" -NoNumberConversion *
    Write-Host -NoNewLine "Users written to XLSX: "
    Write-Host -ForegroundColor Green "OK, Written!"
} catch {
    #Handle exception when writing to output XLSX
    Write-Host -ForegroundColor Red "Fatal Error when writing to XLSX file!"
    exit;
}
