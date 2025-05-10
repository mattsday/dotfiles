Push-Location (Split-Path -parent $profile)
Set-Alias -name ll -value "ls"
function .. { Set-Location .. }

Pop-Location
