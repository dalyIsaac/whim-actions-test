<#
    .SYNOPSIS
    Creates a release.
#>

function Get-Version() {
    $branch = git rev-parse --abbrev-ref HEAD
    $version = ""

    if ($branch.Contains("release/")) {
        $version = $branch.Substring(9)
    }
    else {
        throw "You must be on a release branch to create a release."
    }

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
