<#
    .SYNOPSIS
    Returns the next patch release tag and the current release tag.

    .PARAMETER Channel
    The channel to use in the release tag string. Must be one of the following:
    - `'alpha'`
    - `'beta'`
    - `'stable'`
    Default is `'alpha'`.

    .PARAMETER VersionBump
    The version bump to use in the release tag string. Must be one of the following:
    - `'patch'`
    - `'minor'`
    - `'major'`
    Default is `'patch'`.

    .EXAMPLE
    PS> $currentRelease, $nextRelease = .\scripts\Get-WhimRelease.ps1 -Channel 'alpha' -VersionBump 'minor'
#>

param (
    [Parameter()]
    [string]$Channel = "alpha",

    [Parameter()]
    [string]$VersionBump = "patch"
)

# Check the channel.
$channel = $Channel.ToLower()
if ($channel -ne "alpha" -and $channel -ne "beta" -and $channel -ne "stable") {
    throw "Channel must be one of alpha, beta, or stable"
}

# Check the version bump.
$versionBump = $VersionBump.ToLower()
if ($versionBump -ne "major" -and $versionBump -ne "minor" -and $versionBump -ne "patch") {
    throw "VersionBump must be one of major, minor, or patch"
}

$major, $minor, $patch = .\scripts\Get-WhimVersion.ps1

$currentReleaseTag = ""

$releases = gh release list
if ($null -ne $releases) {
    $priorRelease = $releases | Select-String -Pattern "^v${major}.${minor}" | Select-Object -First 1

    if ($null -ne $priorRelease) {
        $priorRelease = $priorRelease.ToString()
        $currentReleaseTag = $priorRelease.Split("`t")[2]

        $patch = [int] $currentReleaseTag.Split("-").Split(".")[2]
    }
}

if ($versionBump -eq "major") {
    $major += 1
    $minor = 0
    $patch = 0
}
elseif ($versionBump -eq "minor") {
    $minor += 1
    $patch = 0
}
else {
    $patch += 1
}

$commit = (git rev-parse HEAD).Substring(0, 8)

return $currentReleaseTag, "${major}.${minor}.${patch}-${channel}.${commit}"
