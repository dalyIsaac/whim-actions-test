<#
    .SYNOPSIS
    Creates a release.
#>

function Get-Version() {
    $result = git describe --match v*
    $parts = $result.Split('-')

    $version = $parts[0].Substring(1)
    $build = $parts[1]
    $channel = "stable"

    $commit = git rev-parse HEAD
    $commit = $commit.Substring(0, 7)

    $release = "v" + $version + "-" + $channel + "." + $build + "." + $commit
    return $release
}

function Add-Tag() {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $release
    )

    git tag -a $release -m "Release $release"

    $proceed = Read-Host "Push tag $release to origin? (y/N)"
    if ($proceed -cne "y") {
        Write-Error "Aborting"
        exit 1
    }

    git push origin $release
}

function Main() {
    $release = Get-Version
    Add-Tag -Release $release
}

Main
