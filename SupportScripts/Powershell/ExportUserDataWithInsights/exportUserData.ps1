param(
    [Parameter(Mandatory=$true, HelpMessage='Path for your Workplace access token in .json format {"accessToken" : "123xyz"}')] [string]$WPAccessToken,
    [Parameter(Mandatory=$false, HelpMessage='Full path to save the data export file')] [string]$UserDataExportFilePath
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
        Write-Host -ForegroundColor Red $_
        exit;
    }

}

function ScheduleFileDownload
{
    #Scheduling the download of the file
    try
    {
        $result = Invoke-RestMethod -Uri "https://graph.workplace.com/community/export_employee_data"  -Method POST -Headers @{ Authorization = "Bearer " + $global:token } -UserAgent "GithubRep-UserDataExport"

        return $result.id
    }
    catch
    {
        #Handle exception when passed file is not JSON
        Write-Host -ForegroundColor Red "Fatal Error when scheduling the download."
        Write-Host -ForegroundColor Red $_
        exit;
    }
}

function DownloadFile
{
    param (
        $job_ID
    )

    try
    {
        Write-Host "Download scheduled. Job ID:"$job_ID
        do {
            Write-Host "Waiting for the file to be ready..."
            Start-Sleep -Seconds 5
            $result = Invoke-RestMethod -Uri "https://graph.workplace.com/$job_ID" -Headers @{ Authorization = "Bearer " + $global:token } -UserAgent "GithubRep-UserDataExport"
            #Write-Host $result.result
        } while (!$result.result)

        Write-Host "Download URL:"$result.result
        Invoke-WebRequest -Uri $result.result -Headers @{ Authorization = "Bearer " + $global:token } -UserAgent "GithubRep-UserDataExport" -OutFile $UserDataExportFilePath
        Write-Host -ForegroundColor Green "File downloaded to"$UserDataExportFilePath
    }
    catch
    {
        #Handle exception when passed file is not JSON
        Write-Host -ForegroundColor Red "Fatal Error when downloading the file."
        Write-Host -ForegroundColor Red $_
        exit;
    }
}

CheckAccessToken
$job_ID = ScheduleFileDownload
DownloadFile($job_ID)
