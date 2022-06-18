<#
    .SYNOPSIS
    Returns the release string and the prior release tag.

    .PARAMETER Channel
    The channel to use in the release string. Must be one of the following:
    - `'canary'`
    - `'beta'`
    - `'stable'`

    .EXAMPLE
    PS> $release, $priorReleaseTag = .\scripts\Get-ReleaseData.ps1
#>

param (
    [Parameter()]
    [string]$Channel = "canary"
)

$channel = $Channel.ToLower()
$releaseType = "Pre-release"

if ($channel -ne "canary" -and $channel -ne "beta" -and $channel -ne "stable") {
    Write-Error "Channel must be one of canary, beta, or stable"
}

if ($channel -eq "stable") {
    $releaseType = "Release"
}

$version = .\scripts\Get-WhimVersion.ps1

$build = 0
$priorReleaseTag = ""

$releases = gh release list
if ($null -ne $releases) {
    $priorRelease = $releases | Select-String -Pattern "`t${releaseType}"

    if ($null -ne $priorRelease) {
        $priorRelease = $priorRelease.ToString()
        $priorReleaseTag = $priorRelease.Split("`t")[2]

        $priorBuild = $priorReleaseTag.Split(".")[1]
        $build = ([int] $priorBuild) + 1
    }
}

$commit = (git rev-parse HEAD).Substring(0, 8)

return "v${version}-${Channel}.${build}.${commit}", $priorReleaseTag

