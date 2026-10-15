# Runs each MSVC setup script with Visual Studio found at a path containing !
# Usage: powershell -File test/msvc_setup/check.ps1

$ErrorActionPreference = "Stop"
$root = Resolve-Path "$PSScriptRoot\..\.."
$work = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid())
$realPf86 = ${env:ProgramFiles(x86)}
$realVs = & "$realPf86\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -property installationPath

# A Program Files (x86) whose vswhere reports the install through a junction named vs!x
$pf86 = "$work\pf86"
$vs = "$work\vs!x"
New-Item -ItemType Directory -Force "$pf86\Microsoft Visual Studio\Installer" | Out-Null
New-Item -ItemType Junction -Path $vs -Target $realVs | Out-Null
Get-ChildItem $realPf86 -Directory | Where-Object Name -ne "Microsoft Visual Studio" |
   ForEach-Object { New-Item -ItemType Junction -Path "$pf86\$($_.Name)" -Target $_.FullName | Out-Null }
Get-ChildItem "$realPf86\Microsoft Visual Studio" -Directory | Where-Object Name -ne "Installer" |
   ForEach-Object { New-Item -ItemType Junction -Path "$pf86\Microsoft Visual Studio\$($_.Name)" -Target $_.FullName | Out-Null }
Set-Content -Encoding ascii "$work\vswhere.cs" "class P { static void Main() { System.Console.WriteLine(@`"$vs`"); } }"
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /out:"$pf86\Microsoft Visual Studio\Installer\vswhere.exe" "$work\vswhere.cs"

${env:ProgramFiles(x86)} = $pf86
$env:msvc_host_arch = "x64"
$failures = 0
# VsDevCmd writes to stderr, which Stop would turn into an error
$ErrorActionPreference = "Continue"
foreach ($script in "msvc-setup", "msvc64-setup", "msvc-arm64-setup", "msvc-winrt-setup", "msvc-winrt64-setup", "msvc-winrt-arm64-setup") {
   $out = cmd /c "$root\toolchain\$script.bat" 2>&1 | Out-String
   if ($out -match "(?m)^HXCPP_VARS" -and $out -match [regex]::Escape("VSINSTALLDIR=$vs\")) {
      "ok   $script"
   } else {
      "FAIL $script"
      $failures++
   }
}
${env:ProgramFiles(x86)} = $realPf86
Remove-Item -Recurse -Force $work
exit $failures
