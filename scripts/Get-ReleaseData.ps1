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

if ($channel -ne "canary" -and $channel -ne "beta" -and $channel -ne "stable") {
    Write-Error "Channel must be one of canary, beta, or stable"
}

$version = .\scripts\Get-Version.ps1

$priorVersion = $version - 1
$priorRelease = (gh release list) | Select-String -Pattern "v${priorVersion}"

$build = 0
$priorReleaseTag = ""

if ($null -ne $priorRelease) {
    $priorReleaseTag = $priorRelease.Split("`t")[2]
    $build = [int] (git rev-list $priorReleaseTag.. --count)
}

$commit = (git rev-parse HEAD).Substring(0, 8)

return "v${version}-${Channel}.${build}.${commit}", $priorReleaseTag

