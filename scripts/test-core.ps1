# Runs PostureCore tests on Windows.
# Loads fresh Swift env vars and the MSVC linker (link.exe) from VS Build Tools.
$ErrorActionPreference = 'Stop'

foreach ($scope in 'Machine', 'User') {
    $vars = [Environment]::GetEnvironmentVariables($scope)
    foreach ($k in $vars.Keys) { if ($k -ne 'Path') { Set-Item "env:$k" $vars[$k] } }
}
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer"

if (-not (Get-Command link.exe -ErrorAction SilentlyContinue)) {
    $vs = & vswhere.exe -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    Import-Module "$vs\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64' | Out-Null
}

swift test --package-path "$PSScriptRoot\..\PostureCore" @args
