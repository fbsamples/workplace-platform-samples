param(
    [Parameter(Mandatory=$true, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : 123xyz}')] [string]$WPAccessToken,
    [Parameter(Mandatory=$false, HelpMessage='The # of threads on which the export process will span')] [int]$ParallelGrade = 8
)

#Define vars
$SCIMPageSize = 100

$defJobs = {
    
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    function Get-Status {
        If(-Not $_.active) {return "Deactivated"}
        Else {
            If($_."urn:scim:schemas:extension:facebook:accountstatusdetails:1.0".invited -eq $False) {return "Not Invited"} 
            Else {
                If($_."urn:scim:schemas:extension:facebook:accountstatusdetails:1.0".claimed -eq $False) {return "Invited"} 
                Else {return "Claimed"}
            }
        }
    }
    function Get-Timestamp ($UnixDate, $origin) {
        If(-Not $UnixDate -Or ($UnixDate -Eq 0)) {return $null}
        Else {return Get-Date -Date $origin.AddSeconds($UnixDate) -Format s}
    }
    function Call-SCIM-X-Pages ($startIndex, $pageNumber, $SCIMPageSize, $token, $filename) {
        $pagesResult = @()
        For($i = 0; $i -lt $pageNumber; $i++){
            $offset = $startIndex + $i * $SCIMPageSize
            #$count = $offset + $SCIMPageSize - 1
            $next = "https://www.workplace.com/scim/v1/Users?startIndex=$offset&count=$SCIMPageSize"
            #Write-Host "Calling GET $next"
            #Write-Host "Getting users from $offset to $count..." 
            $retries = 2
            $SCIMSuccess = $False
            do {
                try {
                    $results = Invoke-RestMethod -Uri ($next) -Headers @{Authorization = "Bearer " + $token} -UserAgent "WorkplaceScript/ExportUsersSCIM"
                    $SCIMSuccess = $True
                    #Write-Host $results.itemsPerPage
                    If($results.Resources){
                        $pageUsers = $results.Resources | ForEach-Object -Process {$_} | `
                        Select-Object -property `
                            @{N='Full Name';E={$_.name.formatted}}, `
                            @{N='Email';E={$_.username}}, `
                            @{N='User Id';E={$_.id}}, `
                            @{N='Job Title';E={$_.title}}, `
                            @{N='Department';E={$_."urn:scim:schemas:extension:enterprise:1.0".department}}, `
                            @{N='Division';E={$_."urn:scim:schemas:extension:enterprise:1.0".division}}, `
                            @{N='Status';E={$_ | Get-Status}}, `
                            @{N='Claimed';E={$_."urn:scim:schemas:extension:facebook:accountstatusdetails:1.0".claimed}}, `
                            @{N='Claimed Date';E={Get-Timestamp $_."urn:scim:schemas:extension:facebook:accountstatusdetails:1.0".claimDate $origin}}, `
                            @{N='Invited';E={$_."urn:scim:schemas:extension:facebook:accountstatusdetails:1.0".invited}}, `
                            @{N='Invited Date';E={Get-Timestamp $_."urn:scim:schemas:extension:facebook:accountstatusdetails:1.0".inviteDate $origin}}, `
                            @{N='Manager Employee ID';E={$_."urn:scim:schemas:extension:enterprise:1.0".manager.managerID}}, `
                            @{N='Manager Full Name';E={$_."urn:scim:schemas:extension:enterprise:1.0".manager.displayName}}
                    $pagesResult += $pageUsers
                    }
                } catch {
                    #Handle exception when having errors from SCIM API
                    Write-Host -NoNewLine -ForegroundColor Red "Error when getting users from API ($next)"
                    Write-Host " - Retries left: $retries"
                    $retries--
                }
            } While ($retries -ge 0 -and $SCIMSuccess -eq $False)
        }
        return $pagesResult
    }
}

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

#Setup multi-threading options
$jobs = @()
$totalUsers = [int](Invoke-RestMethod -Uri "https://www.workplace.com/scim/v1/Users" -Headers @{Authorization = "Bearer " + $global:token} -UserAgent "WorkplaceScript/ExportUsersSCIM").totalResults
$paral = [math]::Min($ParallelGrade, [math]::Ceiling($totalUsers/$SCIMPageSize))
$pages = [math]::Ceiling($totalUsers/$SCIMPageSize)

#Define filename
$dt = (Get-Date).toString("yyyy-MM-dd-HH_mm", $cultureENUS)
$path = (Get-Location).Path
$filename = "$path/workplace_employees_info_$dt.csv"

Write-Host "We're going to export $totalUsers users with $paral jobs to $filename"

$start = (Get-Date)

For($i = 0; $i -lt $paral; $i++) {
    $step = ([math]::Floor($pages/$paral))
    $jobs += [PSCustomObject]@{
        "JobName" = "SCIM-Job-$i"
        "StartIndex" = 1 + $i * $step * $SCIMPageSize
        "PageNum" = @($step,($step + ($pages % $paral)))[$i -eq ($paral-1)]
        "PageSize" = $SCIMPageSize
        "AuthToken" = $global:token
        "FileName" = $filename
    }
    #Write-Host $jobs[$i]
}

For($i = 0; $i -lt $paral; $i++) {
    Start-Job -Name $jobs[$i].JobName -InitializationScript $defJobs -ScriptBlock {
        param($job)
        #Write-Host $job.JobName
        Call-SCIM-X-Pages $job.StartIndex $job.PageNum $job.PageSize $job.AuthToken $job.FileName
    } -ArgumentList $jobs[$i]
}

Get-Job | Wait-Job

Get-Job | Receive-Job | Export-Csv -Path $filename -NoTypeInformation

Write-Host -NoNewLine "`nUsers written to csv: "
Write-Host -ForegroundColor Green "OK, Written!"

$elapsed = (Get-Date)-$start
$formatelapsed = "{0:HH:mm:ss}" -f ([datetime]$elapsed.Ticks)
Write-Host -NoNewLine -ForegroundColor Yellow "`nTotal time: $formatelapsed"

Get-Job | Remove-Job