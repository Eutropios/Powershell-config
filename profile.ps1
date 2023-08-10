#General styling of output
$PSStyle.FileInfo.Directory = "`e[94m"
$PSStyle.Formatting.TableHeader = "`e[93m"
$PSStyle.FileInfo.Executable = "`e[92m"
$PSStyle.FileInfo.SymbolicLink = "`e[96m"

#Aliases
New-Alias touch New-Item
New-Alias which Get-Command

#Functions

#Custom exception that takes a custom message
class CustomException : Exception {
    [string] $additionalData

    CustomException($Message, $additionalData) : base($Message) {
        $this.additionalData = $additionalData
    }
}

#Function that finds a file or subdirectory in $filename directory
function gfind ($filename) {
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

#Function that displays user perms of a specific directory or file
#Display as a table
function Get-Perms ($folder) {
    (Get-Acl $folder).access | Select-Object `
    @{Label = "Identity"; Expression = { $_.IdentityReference } }, `
    @{Label = "Right"; Expression = { $_.FileSystemRights } }, `
    @{Label = "Access"; Expression = { $_.AccessControlType } }, `
    @{Label = "Inherited"; Expression = { $_.IsInherited } } | Format-Table -auto
}

#kills ssh-agent in powershell, requires gsudo program
function killssh {
    gsudo taskkill /F /IM ssh-agent.exe /T
}

#looks up geolocation of a given ip address
function geoip ($ipAddress) {
    curl "https://ipinfo.io/$ipAddress/json"
}

function psfind ($processid) {
    Get-Process -Id $processid
}

#Overrides the command prompt
function prompt {
    $esc = "$([char]27)"
	("PS $esc[92m$([Environment]::UserName)$esc[0m@" `
        + "$esc[96m$($env:COMPUTERNAME.ToLower())$esc[0m:" `
        + "$esc[94m$((Get-Location).Path)$esc[0m$ ").Replace($HOME, "~")
}
