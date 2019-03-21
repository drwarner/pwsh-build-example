## Pseudo - CI build
$path = "c:\code\mock-repo"

## Grab build tool from GHE Releases

## run the build
$ErrorActionPreference = "stop"
Import-Module .\manifestGenerator
if (Test-GitRepo -LocalGitPath $path) {
    Write-Host "Getting branch name"
    $name = git rev-parse --abbrev-ref HEAD
} else {
    throw
}
Write-Host "Getting Deltas"
$d = Get-GitDeltas -LocalGitPath $path
Write-Manifest -LocalGitPath $path -name $name -Contents $d -Description "auto generated" -Instructions "follow normal release"

## run package on pull request
Import-Module ./release-packaging -Force
New-ReleasePackage -ManifestName "$name.txt" -RepoCheckoutPath $path