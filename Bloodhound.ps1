###################################################################################################
## Author: Oliver Aflaki
## 2023/01/03
## Category: Manual DevSecOps Tools
## Powershell 7
## Version 1.0
## Reference https://learn.microsoft.com/en-us/rest/api/azure/devops/?view=azure-devops-rest-7.1
###################################################################################################

# Organization
$organization = "your_organization_name"
# Project Name
$project = "your_project_name"
# PAT Token
$pat = "token_string_goes_here"
# Url Devops REST API
$baseUrl = "https://dev.azure.com/$organization/$project/_apis"
# List the repositories
$url = "$baseUrl/git/repositories"
$response = Invoke-RestMethod -Uri $url -Method get -Headers @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)")) }
$repositories = $response.value
# Scan function
function Bloodhound-Scan {
    param(
        $repository
    )

    # List Commits
    $commitsUrl = "$baseUrl/$($repository.remoteUrl.url)/git/repositories/$($repository.name)/commits"
    $commits = Invoke-RestMethod -Uri $commitsUrl -Method Get -Headers @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)")) }

    # Iterate trough every commit
    foreach ($commit in $commits.value) {
        # Get the list of commited changes
        $changesUrl = "$baseUrl/$($repository.remoteUrl.url)/git/repositories/$($repository.name)/commits/$($commit.commitId)/changes"
        $changes = Invoke-RestMethod -Uri $changesUrl -Method Get -Headers @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)")) }

        # Iterate trough every change
        foreach ($change in $changes.value) {
            # Download the file
            $fileUrl = "$baseUrl/$($repository.remoteUrl.url)/git/repositories/$($repository.name)/items/$($change.item.path)?download=true"
            $file = Invoke-WebRequest -Uri $fileUrl -Method Get -Headers @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)")) }

            # Search for string (password)
            if ($file.Content -match "password") {
                Write-Host "Secret found in file $($change.item.path) in repository $($repository.name) at commit $($commit.commitId)"
            }
        }
    }
}
