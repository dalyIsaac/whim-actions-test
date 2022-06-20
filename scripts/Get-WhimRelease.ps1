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
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateSet("alpha", "beta", "stable")]
    [string]$Channel = "alpha",

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateSet("patch", "minor", "major")]
    [string]$VersionBump = "patch"
)

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
