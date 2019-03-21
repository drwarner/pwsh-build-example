## Pseudo - CI build
$ManifestName = ""
$CheckoutPath = ""

## Check out Database Repo

## Grab build tool from GHE Releases

Set-Location $CheckoutPath
Import-Module ./release-packaging -Force
New-ReleasePackage -ManifestName $ManifestName -RepoCheckoutPath $CheckoutPath