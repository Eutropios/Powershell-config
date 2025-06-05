#General styling of output
$PSStyle.FileInfo.Directory = "`e[94m"
$PSStyle.Formatting.TableHeader = "`e[93m"
$PSStyle.FileInfo.Executable = "`e[92m"
$PSStyle.FileInfo.SymbolicLink = "`e[96m"

#Aliases
New-Alias touch New-Item
New-Alias which Get-Command
New-Alias grep rg

# Custom classes

#Custom exception that takes a custom message
class CustomException : Exception {
    [string] $additionalData

    CustomException($Message, $additionalData) : base($Message) {
        $this.additionalData = $additionalData
    }
}

#Alias-functions, functions that act like aliases

function npp {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromRemainingArguments = $true
        )][string[]]
        $args
    )
    Start-Process notepad++ $args
}

#Functions

# Function to add:
# First, in Explorer, browse to the subdirectory where your code resides. Then type 'powershell' in the Explorer bar, which will open a copy of Powershell there. Then type:
#(dir -include *.cpp, *.h -recurse | select-string "^").Count

#To exclude blank lines:
#(dir -include *.cpp, *.h -recurse | select-string "^(\s*)$" -notMatch).Count

#Or, to also exclude '//' comments:
#(dir -include *.cpp, *.h -recurse | select-string "^(\s*)//" -notMatch | select-string "^(\s*)$" -notMatch).Count

#Change the '*.cpp' and '.h' to whatever file extensions you are interested in. Remove '*.cpp' if you are only interested in headers.


#Function that finds a file or subdirectory in $filename directory
function Find-File {
    [CmdletBinding()]
    [Alias("gfind")]
    param (
        [string]$filename
    )
    try {
        if ([string]::IsNullOrWhiteSpace($filename)) {
            throw [CustomException]::new('Error message', 'Please specify a target')
        }
        else {
            Get-ChildItem -r -fi $filename | Select-Object FullName
        }
    }
    catch [CustomException] {
        # NOTE: To access your custom exception you must use $_.Exception
        Write-Output $_.Exception.additionalData
    }
}

function Get-ChildItem-Readable {
    [CmdletBinding()]
    [Alias("lsr")]
    [Alias("gcir")]
    param (
        [PSDefaultValue(Help = ".")]
        $folder = "."
    )
    Get-ChildItem $folder | Select-Object Name, @{Name = "KiloBytes"; Expression = { $_.Length / 1KB } }
}

function Get-Perms {
    <#
    .SYNOPSIS
    Display user permissions of a specific file or directory.

    .DESCRIPTION
    Display user permissions of a specific file or directory.
    If no parameter is supplied, the current directory is used.

    .PARAMETER fileOrDir
    The file or directory to display the permissions of. Defaults to current directory.

    .INPUTS
    None. Objects cannot be piped into this function

    .OUTPUTS
    System.Object. Get-Perms prints the permissions of the file or directory as a table.

    .EXAMPLE
    Function without passing any arguments
    PS> Get-Perms

    .EXAMPLE
    Function passing a directory
    PS> Get-Perms ~\Desktop

    .EXAMPLE
    Function passing a file
    PS> Get-Perms ~\Documents\foo.txt
    #>
    [CmdletBinding()]
    [Alias("getperms")]
    param (
        [PSDefaultValue(Help = ".")]
        $fileOrDir = "."
    )
    (Get-Acl $fileOrDir).access | Select-Object `
    @{Label = "Identity"; Expression = { $_.IdentityReference } }, `
    @{Label = "Right"; Expression = { $_.FileSystemRights } }, `
    @{Label = "Access"; Expression = { $_.AccessControlType } }, `
    @{Label = "Inherited"; Expression = { $_.IsInherited } } | Format-Table -auto
}

function Stop-Agents {
    <#
    .SYNOPSIS
    Kill any active ssh-agent processes. REQUIRES gsudo TO RUN.

    .DESCRIPTION
    Requests admin privileges via UAC (User Account Control) and ends all active ssh-agent processes.
    REQUIRES gsudo TO RUN.

    .INPUTS
    None. You cannot pipe objects to killssh.

    .OUTPUTS
    System.String. killssh returns a string with either the number of ssh-agent processes killed, or with an ERROR
    stating that there were no ssh-agent processes active.

    .EXAMPLE
    PS> killssh
    #>
    [CmdletBinding()]
    [Alias("killssh")]
    [Alias("Kill-Agents")]
    param()
    gsudo taskkill /F /IM ssh-agent.exe /T
}

#looks up geolocation of a given ip address
function geoip ($ipAddress) {
    curl "https://ipinfo.io/$ipAddress/json"
}

#gets name of process by processid
function Get-ProcessName {
    [CmdletBinding()]
    [Alias("psfind")]
    [Alias("psname")]
    param(
        [Parameter(Mandatory = $true)]
        [string]$processid
    )
    Get-Process -Id $processid
}

function update-all {
    <#
    .SYNOPSIS
    Executes a bunch of upgrade commands

    .DESCRIPTION
    Takes an array of commands in the form of strings and executes them in subshells. Elevates user privileges to
    administrator if needed. Meant to be set and forget.

    .EXAMPLE
    update-all

    .NOTES
    Credit for the original script goes to https://github.com/killjoy1221. I simply ported this to PowerShell.
    #>
    [CmdletBinding()]
    [Alias("upgrade-all")]
    param()
    $NO_FORMAT = "$([char]27)[0m"

    function Run {
        param (
            [Parameter(Mandatory = $true)]
            [string]$prog,

            [Parameter(Mandatory = $true)]
            [array]$progargs
        )
        # Replace "gsudo" with "sudo" if you have the sudo for windows tool from the dev channel
        if ($prog -eq "gsudo") {
            $prog = $progargs[0]
            $progargs = $progargs[1..$progargs.Length]
        }

        # Check if the program exists in the command path
        if (Get-Command $prog -ErrorAction SilentlyContinue) {
            Write-Host "$C_TEAL`$ $NO_FORMAT $prog $($progargs -join ' ')"
            & $prog @progargs
        }
    }

    function Main {
        Run -prog "rustup" -progargs "update"
        Run -prog "cargo-install-update" -progargs "install-update", "--all"
        Run -prog "winget" -progargs "upgrade", "--all"
        Run -prog "pnpm" -progargs "update", "-gL"
        Run -prog "uv" -progargs "tool", "upgrade", "--all"
        Run -prog "pip" -progargs "cache", "purge"
        Run -prog "pip" -progargs "list", "--outdated"
    }

    Main
}

#Overrides the command prompt
function prompt {
    $esc = "$([char]27)"
    ("PS $esc[92m$([Environment]::UserName)$esc[0m@" `
        + "$esc[96m$($env:COMPUTERNAME.ToLower())$esc[0m:" `
        + "$esc[94m$((Get-Location).Path)$esc[0m$ ").Replace($HOME, "~")
}

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58
