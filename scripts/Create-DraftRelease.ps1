<#
    .SYNOPSIS
    Creates a draft release on GitHub.

    .EXAMPLE
    PS> .\scripts\Create-DraftRelease.ps1
#>

# Make a param channel
param (
    [Parameter()]
    [string]$Channel = "canary"
)

# Create the release version string.
$release, $priorReleaseTag = .\scripts\Get-ReleaseData.ps1 -Channel $Channel

# Get the release notes.
$resp = gh api repos/$env:GITHUB_REPOSITORY/releases/generate-notes `
    -H "Accept: application/vnd.github.v3+json" `
    -f tag_name=$env:release `
    -f previous_tag_name=$priorReleaseTag
| ConvertFrom-Json

$notes = $resp.body ?? "Initial release"

Write-Host "Draft release version: $release"

# If env:CI is set, skip the prompt
if (!$env:CI) {
    $proceed = Read-Host "Are you sure you want to create a draft release? (y/N)"

    if ($proceed -cne "y") {
        Write-Host "Aborting..."
        exit 1
    }
}

Write-Host $notes

# Create the release.
gh release create $release --draft --title "Whim ${release}" --notes $notes
