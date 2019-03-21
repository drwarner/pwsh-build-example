using module ..\src\release-packaging
Import-Module Pester

#Unit test each bit of functionality. Focus on the parser because it is the most modularized.
$GitDbRepo = "test-data"
$CheckoutDir = Join-Path (Get-Location) "\test-data\"
$SrcPath = Join-Path (Get-Location) "\test-data\src"

Describe "ParseManifestFromFile" {        
    It "Parses a manifest where contents are empty" {        
        {
            $ManifestPath = Join-Path $CheckoutDir "manifests\empty_contents.txt"
            $NewManifest= [DbManifest]::new()
            $NewManifest.ParseManifestFromFile($ManifestPath,$GitDbRepo)
            foreach ($Item in $NewManifest.Contents) {
                Write-Host -ForegroundColor Magenta "$item"
            }
        } | should -Throw
    } 
    It "Parses a manifest where contents have non-standard slashes" {
        $ManifestPath = Join-Path $CheckoutDir "manifests\slashy_path.txt"
        $NewManifest= [CustomManifest]::new()
        $NewManifest.ParseManifestFromFile($ManifestPath,$GitDbRepo)
        $NewManifest.contents | should -Not -BeNullOrEmpty
        {
            foreach ($Item in $NewManifest.Contents) {
                Write-Host -ForegroundColor Magenta "$item"
                $UnCheckedPath = Join-Path $SrcPath $Item
                Write-Host -ForegroundColor DarkMagenta "resolving $UnCheckedPath"
                Resolve-Path $UnCheckedPath
            }
        } | should -not -Throw 
    }
}

Describe "Manifest.ParseGitHubRepo" {    
    It "parses a DBA repo name" {
        $NewManifest= [CustomManifest]::new()
        {
            $return = $NewManifest.ParseGitHubRepo('DBA-cmxdb-sybase')
            Write-Host -ForegroundColor DarkMagenta "return: $return"
        } |  Write-Host
    }    
    It "Parses a Unix repo name" {
        $NewManifest= [CustomManifest]::new()
        {
            $return = $NewManifest.ParseGitHubRepo('ESUnix-store')
            Write-Host -ForegroundColor DarkMagenta "return: $return"
        } 
    } 
    It "Parses a repo with no allowed admin team" {
        $NewManifest= [CustomManifest]::new()
        {
            $return = $NewManifest.ParseGitHubRepo('edw-some_repo')            
        } | should -Throw
    }
    It "Parses a bad repo" {
        $NewManifest= [CustomManifest]::new()
        {
            $return = $NewManifest.ParseGitHubRepo('whocares')
            Write-Host -ForegroundColor DarkMagenta "return: $return"
        } | should -Throw
    } 

}
