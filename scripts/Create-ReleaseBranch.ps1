<#
	.SYNOPSIS
	Create a release commit, branch, tag, and push them to the remote.

	.DESCRIPTION
	This command will:
	1. Verify that the repository is clean.
	2. Assert that the current branch is the main branch.
	3. Calculate the next version number.
	4. Verify that there are no commits or tags containing the version number.
	5. Update the version number in the Whim source code.
	6. Create a release commit, and push the commit to the remote.
	7. Create a new branch for the release, and push it to the remote.

	.EXAMPLE
	PS> ./Create-ReleaseBranch.ps1
#>

<#
	.SYNOPSIS
	Assert that the current branch is the main branch.
#>
function Assert-GitMainBranch() {
	Write-Host "Checking the current branch..."

	$branch = (git rev-parse --abbrev-ref HEAD)

	if ($branch -cne "main") {
		throw "Not on the main branch: $branch"
	}
}

<#
	.SYNOPSIS
	Verify that the codebase is clean.
#>
function Assert-GitClean() {
	Write-Host "Checking the status of the repository..."

	$status = (git status --porcelain)

	if ($null -ne $status) {
		Write-Host $status
		throw "Git status is not clean:"
	}
}

<#
	.SYNOPSIS
	Bumps the version number in the project file.
#>
function Get-NextVersion() {
	Write-Host "Calculating the next version..."

	# Get the current version.
	$xml = [Xml] (Get-Content .\src\Whim.Runner\Whim.Runner.csproj)

	$version = [int] $xml.Project.PropertyGroup[0].Version
	$nextVersion = $version + 1

	# Check with the user that the next version is correct.
	Write-Host "The current version is $version"
	Write-Host "The next version will be $nextVersion"
	$proceed = Read-Host "Is this correct? (y/N)"

	if ($proceed -cne "y") {
		Write-Error "Aborting"
		exit 1
	}
	return $nextVersion
}

<#
	.SYNOPSIS
	Ensure no branch or tag exists named $nextVersion.
#>
function Assert-GitVersion() {
	param (
		[Parameter(Mandatory = $true)]
		[String]
		$nextVersion
	)

	Write-Host "Checking for existing tags and branches..."

	git fetch

	$nextVersion = "v$nextVersion"

	# Verify there is no branch on the remote named $nextVersion.
	$branches = git branch -r
	$branches = $branches.Split("\n")
	if ($branches.Contains($nextVersion)) {
		Write-Error "A branch on the remote containing the string $nextVersion already exists"
		exit 1
	}

	# Verify there is no branch locally named $nextVersion.
	$branches = git branch
	if ($branches.Contains($nextVersion)) {
		Write-Error "A branch locally containing the string $nextVersion already exists"
		exit 1
	}

	# Verify that there is no tag named $nextVersion.
	$tags = git tag
	if (($tags -ne $null) -and ($tags.Contains($nextVersion))) {
		Write-Error "A tag containing the string $nextVersion already exists"
		exit 1
	}
}

<#
	.SYNOPSIS
	Sets the version number of Whim.
#>
function Set-Version() {
	param (
		[Parameter(Mandatory = $true)]
		[string]$version
	)

	$proceed = Read-Host "Do you want to update the version number in csproj files? (y/N)"
	if ($proceed -cne "y") {
		Write-Error "Aborting"
		exit 1
	}

	Write-Host "Updating the version number..."

	# Check for set-version.
	if (!(Get-Command setversion -ErrorAction SilentlyContinue)) {
		$proceed = Read-Host "dotnet-setversion not found. Install now? (y/N)"
		if ($proceed -cne "y") {
			Write-Error -Message "dotnet-setversion not found. Aborting."
			exit 1
		}

		dotnet tool install -g dotnet-setversion
	}

	setversion -r $Version
}

<#
	.SYNOPSIS
	Creates and pushes a commit with the current changes.
#>
function Add-BumpCommit() {
	param (
		[Parameter(Mandatory = $true)]
		[String]
		$nextVersion
	)

	$proceed = Read-Host "Do you want to create a commit to store updated version number? (y/N)"
	if ($proceed -cne "y") {
		Write-Error "Aborting"
		exit 1
	}

	git add .
	git commit -m "Bumped version to $nextVersion" -S

	# Ask the user if they want to push.
	$proceed = Read-Host "Push commit to remote? (y/N)"
	if ($proceed -cne "y") {
		Write-Error "Aborting"
		exit 1
	}

	git push
}

<#
	.SYNOPSIS
	Tag the commit with the next version.
#>
function Add-Tag() {
	param (
		[Parameter(Mandatory = $true)]
		[String]
		$nextVersion
	)

	$proceed = Read-Host "Do you want to tag the commit? (y/N)"
	if ($proceed -cne "y") {
		Write-Error "Aborting"
		exit 1
	}
	git tag -a $nextVersion -m "$nextVersion"

	# Ask the user if they want to push.
	$proceed = Read-Host "Push tag to remote? (y/N)"
	if ($proceed -ne "y") {
		Write-Error "Aborting"
		exit 1
	}

	git push --tags
}

<#
	.SYNOPSIS
	Creates and pushes a release branch.
#>
function Add-ReleaseBranch() {
	param (
		[Parameter(Mandatory = $true)]
		[String]
		$nextVersion
	)

	$proceed = Read-Host "Do you want to create a release branch? (y/N)"
	if ($proceed -cne "y") {
		Write-Error "Aborting"
		exit 1
	}

	# Ask the user if they want to push.
	$proceed = Read-Host "Push branch to remote? (y/N)"
	if ($proceed -ne "y") {
		Write-Error "Aborting"
		exit 1
	}

	git push --set-upstream origin $nextVersion
}


# Assert-GitMainBranch
# Assert-GitClean
$nextVersion = Get-NextVersion

$versionString = "v$nextVersion"
Assert-GitVersion($versionString)

Set-Version($nextVersion)

Add-BumpCommit($versionString)
Add-Tag($versionString)
Add-ReleaseBranch($versionString)
