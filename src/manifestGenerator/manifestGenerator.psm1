function Test-GitRepo{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LocalGitPath
    )

    Set-Location $LocalGitPath
    try {
        $RemoteUrl = $(Invoke-expression "git config --get remote.origin.url")
        if ($RemoteUrl -match "([^\/]+)(\.git)") {
            $RemoteRepo = $Matches[1]
        }
        $GitMeta = @{
            GitBranch=$(Invoke-expression "git rev-parse --abbrev-ref HEAD")
            GitRemoteRepo=$RemoteRepo
            GitRef=$(Invoke-expression "git rev-parse HEAD")            
        }
        return $GitMeta
    } catch {
        throw $_
    }
}

function Get-GitDeltas {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LocalGitPath
    )

    Set-Location $LocalGitPath
    try {
        $GitDeltas=$(Invoke-Expression "git diff --name-only master" | Where-Object {$_ -match "src/"})
        return $GitDeltas
    } catch {
        throw $_
    }    
}

function Write-Manifest {
    [cmdletbinding()]
        param(    
        [Parameter(Mandatory=$true)]
            [string]$LocalGitPath,    
        [Parameter(Mandatory=$true)]
            [string]$Name,
        [Parameter()]
            [string]$Description,
        [Parameter()]
            [string[]]$Instructions,
        [Parameter(Mandatory=$true)]
            [string[]]$Contents
    )

    function writeManifest {
        if (!(Test-Path $ManifestPath)) {
            New-Item $ManifestPath -ItemType File
        } else {
            throw "$ManifestPath exists!"
        }        
        Add-Content $ManifestPath "[version]"
        Add-Content $ManifestPath "# semantic version of package (required)"
        Add-Content $ManifestPath "1.0.0"
        Add-Content $ManifestPath "`n"
        Add-Content $ManifestPath "[contents]"
        Add-Content $ManifestPath "# contents of the package (required)"
        foreach ($Item in $Contents) {    
            Add-Content $ManifestPath $Item
        }
        Add-Content $ManifestPath "`n"
        Add-Content $ManifestPath "[description]"
        Add-Content $ManifestPath "# description of the package (optional)"
        if ($Description) {
            Add-Content $ManifestPath $Description
        }
        Add-Content $ManifestPath "`n"
        Add-Content $ManifestPath "[instructions]"
        Add-Content $ManifestPath "# instructions for deployment (optional)"        
        foreach ($Item in $Instructions) {
            Add-Content $ManifestPath $Item
        }
    }

    try {       
        $ManifestPath = Join-Path $LocalGitPath "\manifests\$Name.txt"
        writeManifest | Out-Null
        return @{manifest=$ManifestPath}
    } catch {
        throw $_
    }
}