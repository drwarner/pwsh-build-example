## Pseudo - CI build
$ManifestName = "mock-release"
$CheckoutPath = "c:\code\mock-repo"

## Check out Database Repo

## Grab build tool from GHE Releases

## run the build
$ErrorActionPreference = "stop"
Set-Location $CheckoutPath
Import-Module ./release-packaging -Force
New-ReleasePackage -ManifestName "$ManifestName.txt" -RepoCheckoutPath $CheckoutPath