using namespace System.Text.RegularExpressions;

# This is the Semver namespace in Powershell 6 module format

class Semver {
    #public
    [int]$Major;
    [int]$Minor;
    [int]$Patch;
    [string]$PreRelease;
    [string]$Build;

    #constructor
    Semver ([string]$UnsanitizedInput) {    
        # Insane full Semver format
        [Regex]$Pattern = "^(?'MAJOR'0|[1-9]\d*)\.(?'MINOR'0|[1-9]\d*)\.(?'PATCH'0|[1-9]\d*)(-(?'PRE_RELEASE'(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+(?'BUILD'[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$";
        $_validatedInput = $Pattern.Match($UnsanitizedInput);
        if ($_validatedInput.Success) {
            $this.Major =  $_validatedInput.Groups["MAJOR"].Value;
            $this.Minor =  $_validatedInput.Groups["MINOR"].Value;
            $this.Patch =  $_validatedInput.Groups["PATCH"].Value;
            if ($_validatedInput.Groups["PRE_RELEASE"]) {
                $this.PreRelease = $_validatedInput.Groups["PRE_RELEASE"].Value;
            }
            if ($_validatedInput.Groups["BUILD"]) {
                $this.Build = $_validatedInput.Groups["BUILD"].Value;
            }
        } else {
            throw [exception]::new("Regex Match Failure");
        }
    }

    #to string
    [string] ToString() {
        $_stringified = "{0}.{1}.{2}" -f $this.Major,$this.Minor,$this.Patch;
        if ($this.PreRelease) {
            $_stringified = $_stringified + '-' + $this.PreRelease;
        }
        if ($this.Build) {
            $_stringified = $_stringified + '+' + $this.Build;
        }
        return $_stringified;
    }
}