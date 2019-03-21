using namespace System.IO;
using module .\semver.psm1;
# using namespace System.Automation.Semver ## Only in PWSH 6!

function New-ReleasePackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
            [string]$ManifestName,
        [Parameter(Mandatory=$true)]
            [string]$RepoCheckoutPath
    )
    try {                                     
        #Make sure the repo made it correctly 
        ## Note that the \manifests\ subdir is hardcoded in the repo path. It will always look for manifests there, and source at \src\
        $ManifestPath = Join-Path $RepoCheckoutPath -ChildPath $("\manifests\{0}" -f $ManifestName)
        Resolve-Path $ManifestPath
        Write-Host "Creating new generic manifest at $ManifestPath"        
        $Manifest = [Manifest]::new($ManifestPath);
        $Package = [Package]::new($Manifest);
        $Package.CreateUpackPackage($RepoCheckoutPath);
    } catch {        
        throw "unhandled exception:`n$($_.Exception)"
    }
}

class ManifestParser {
    static [array] parseManifest([string]$ManifestPath) {
        $file = [File]::ReadAllLines($ManifestPath);
        $parsedFile = @();
        [string]$sectionName = $null;
        [string[]]$sectionValues = $null;
        
        for ($i=0;$i -le $file.Count;$i++) {
            $line = $file[$i];
            switch -regex ($line) {
                # whitespace
                '^\s*$' {
                    Write-Verbose "ignoring whitespace";
                    break;
                }
                # comments
                '^#.*$' {
                   Write-Verbose "skipping comment: $line";
                   break;
                }
                # sections
                '^\[(.+)\]' {
                    if ($sectionName){
                        $parsedFile += @{$sectionName=$sectionValues};
                        $sectionValues = $null;
                    }
                    # $matches;
                    $sectionName = $matches[1];
                    break;
                }
                #values
                '^[^#].*' {
                    if (!$sectionName) {
                        throw 'invalid manifest format!';
                    }
                    [string[]]$sectionValues += $line;
                    break;
                }
            }
            #If it's the end of the file, add the last section
            if ($i -eq $file.Count) {
                $parsedFile += @{$sectionName=$sectionValues};
            }        
        }
        #Add the static name section parsed from the filename
        $parsedFile += @{name=(([FileInfo]::new($ManifestPath)).BaseName)};
        return $parsedFile
    }    
}

class Manifest {
    [FileInfo]$File;
    [string]$name;
    [Semver]$version;
    [string[]]$contents;
    [string[]]$description;
    static [object[]]$Schema = @(
        @{
            name='name';
            required=$true;
            limit=1;
        },
        @{
            name='version';
            required=$true;
            limit=1;
        },
        @{
            name='contents';
            required=$true;
        },
        @{
            name='description';
        }
    )

    Manifest ([string]$ManifestPath) {
        try {
            $this.File = [FileInfo]::new($ManifestPath);
            $parsedManifest = [ManifestParser]::parseManifest($this.File);
            # For every field in the schema, validate any constraints on the parsed input and then apply the values
            foreach ($Field in [Manifest]::schema) {
                [string[]]$CurrentField = @();
                if ($parsedManifest.$($Field.name)) {
                    $CurrentField = $parsedManifest.$($Field.name);
                } else {
                    #Apply the required constraint
                    if ($Field.required) {
                        throw "Missing required field: $($Field.name)";
                    }                                        
                }
                #Apply the limit constraint
                if ($Field.limit) {
                    if ($CurrentField.Count -gt $Field.limit) {
                        throw "Too many $Field returned. Limit is $($Field.limit)";
                    }                    
                }
                if ($CurrentField.Count -eq 1) {
                    [string]$CurrentField = $CurrentField;
                }
                $this.$($Field.name) = $CurrentField;
            }
        } catch {
            throw $_.Exception
        }
    }
}

class Package {
    #public
    [Manifest]$Manifest
    [FileInfo]$ArchiveFile

    #constructor
    Package ([Manifest]$Manifest) {
        $this.Manifest = $Manifest
    }

    # Packaging for Upack format (ProGet)
    [void] CreateUpackPackage([string]$ArtifactDir) {
        try {
            $SrcPath = Join-Path $this.Manifest.File.Directory.Parent.FullName "\src"
            $ArtifactPath = Join-Path $ArtifactDir ("\{0}\" -f $this.Manifest.File.BaseName)
            New-Item -ItemType Directory $ArtifactPath -Force
            # Required for upack format
            $PackagePath = Join-Path $ArtifactPath "\package"
            New-Item -ItemType Directory $PackagePath -Force     
            Copy-Item $this.Manifest.File $PackagePath
            foreach ($Item in $this.Manifest.Contents) {                
                if ($Item -match "^[\/\\]?src[\/\\](.*)") {
                    Write-Host "Parsing $Item"
                    $Item = $matches[1]
                }
                Write-Host "Including $Item"
                $ItemPath = Resolve-Path (Join-Path $SrcPath $Item)
                $DestinationPath = Join-Path $PackagePath $Item
                New-Item (Split-Path $DestinationPath -Parent) -ItemType Directory -Force
                Copy-Item $ItemPath $DestinationPath
            }
            # Add Mandatory upack fields
            $Metadata= [ordered]@{
                name=$this.Manifest.name
                version=$this.Manifest.version.ToString()                                
            }
            # Add optional upack fields
            if ($this.Manifest.description) {
                $Metadata += @{description=$this.Manifest.description}
            }
            # Upack manifest format
            Set-Content "$ArtifactPath\upack.json" -Value ($Metadata | ConvertTo-Json)
            if ($this.Manifest.GitMetadata) {
                Set-Content "$ArtifactPath\git-metadata.json" -Value ($this.manifest.GitMetadata | ConvertTo-Json)
            }
            $ZipArchive = "$ArtifactDir\$($this.Manifest.File.BaseName).zip"            
            if (Test-Path $ZipArchive) {
                Remove-Item $ZipArchive -Force 
            }             
            Write-Host "Compressing Archive at $ZipArchive"
            Compress-Archive "$ArtifactPath\*" $ZipArchive               
            $this.ArchiveFile = [FileInfo]::new($ZipArchive)
        } catch {
            throw $_
        }
        finally {
            #clean up the artifact
            if (Test-Path $ArtifactPath) {
                Remove-Item $ArtifactPath -Force -Recurse
            }                        
        }
    }
}