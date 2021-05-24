param(
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

#Export last activity date for each group based on latest post date
try {    
    $global:groups = @()
    #Get posts of a group from API calls
    $next = "https://graph.workplace.com/community/groups/?fields=id,name,owner{first_name, last_name, email},privacy,updated_time,archived"
    do {
        #Get specific group in the community via SCIM API
        $results = Invoke-RestMethod -Uri ($next) -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ExportGroupLastActivityDate"
        if ($results) {

            $results.data.ForEach({
                $group_data = $_

                #Get group stats
                If($Interactive.IsPresent) {
                    Write-Host "Crunching the last time $($_.id) was active..."
                    }

                $last_update = [DateTime]$_.updated_time
                $last_activity_data = @{
                    active_last_30d = If ($last_update -lt (Get-Date).AddDays(-30)) {$False} Else {$True};
                    active_last_60d = If ($last_update -lt (Get-Date).AddDays(-60)) {$False} Else {$True};
                    active_last_90d = If ($last_update -lt (Get-Date).AddDays(-90)) {$False} Else {$True};
                    active_last_180d = If ($last_update -lt (Get-Date).AddDays(-180)) {$False} Else {$True};
                    active_last_365d = If ($last_update -lt (Get-Date).AddDays(-365)) {$False} Else {$True};
                    active_last_730d = If ($last_update -lt (Get-Date).AddDays(-730)) {$False} Else {$True};
                }

                $group_data | Add-Member -NotePropertyName "stats" -NotePropertyValue $last_activity_data
                $global:groups += $group_data
            })

            if($results.paging.cursors.after) {
                $after = $results.paging.cursors.after
                $next = "https://graph.workplace.com/community/groups/?fields=id,name,owner{first_name, last_name, email},privacy,updated_time,archived&after=$after"
            }
            else {$next = $null}
        }
        else {$next = $null}
    } while($next) 
} catch {
    #Handle exception when getting users from API throws an error
    Write-Host -ForegroundColor Red "Fatal Error when getting posts via API!"
    exit;
}

try {
    
    $xlsxFile = "./last-activity-stats.xlsx" 
    
    #$xlp = 
    $global:groups | `
    ForEach-Object -Process {$_} | `
    Select-Object -property `
    @{N='Id';E={$_.id}}, `
    @{N='Name';E={$_.name}}, `
    @{N='Owner';E={"$($_.owner.first_name) $($_.owner.last_name) ($($_.owner.email))"}}, `
    @{N='Privacy';E={$_.privacy}}, `
    @{N='Archived';E={$_.archived}}, `
    @{N='Updated Time';E={$_.updated_time}}, `
    @{N='Active last 30d';E={$_.stats.active_last_30d}}, `
    @{N='Active last 60d';E={$_.stats.active_last_60d}}, `
    @{N='Active last 90d';E={$_.stats.active_last_90d}}, `
    @{N='Active last 6mo';E={$_.stats.active_last_180d}}, `
    @{N='Active last 1y';E={$_.stats.active_last_365d}}, `
    @{N='Active last 2y';E={$_.stats.active_last_730d}} |`
    Export-Excel -Path $xlsxFile -NoNumberConversion * 

    Write-Host -NoNewLine "Analytics written to XLSX: "
    Write-Host -ForegroundColor Green "OK, Written!"
} catch {
    #Handle exception when writing to output XLSX
    Write-Host -ForegroundColor Red "Fatal Error when writing to XLSX file!"
    exit;
}