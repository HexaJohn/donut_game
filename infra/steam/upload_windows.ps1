# Builds Donut for Windows and uploads it to Steam with SteamPipe, from this PC.
#
#   .\upload_windows.ps1 -Account BUILD_ACCOUNT [-Beta BRANCH] [-Preview] [-AiText] [-SkipBuild]
#
# -Account    the Steam account with build permissions (steamcmd asks for its
#             password and Steam Guard code the first time, then remembers it)
# -Beta       also set the build live on this beta branch (it must exist in
#             Steamworks). The default branch is set live by hand.
# -Preview    check everything without uploading
# -AiText     ship every line's AI-written original instead of
#             assets/copy/donut_text.txt (see lib/res/game_text.dart)
# -SkipBuild  upload the Release folder as it is, without building
#
# Uploads the Windows depot only; the macOS depot goes up from a Mac with
# upload.sh. Needs the Steamworks SDK unzipped into infra\steam\sdk, so that
# infra\steam\sdk\sdk\tools\ContentBuilder exists.
param(
  [Parameter(Mandatory = $true)][string]$Account,
  [string]$Beta = '',
  [switch]$Preview,
  [switch]$AiText,
  [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$AppId = if ($env:STEAM_APP_ID) { $env:STEAM_APP_ID } else { '1905500' }
$WindowsDepot = '1905502'
$Builder = 'sdk\sdk\tools\ContentBuilder\builder\steamcmd.exe'
$SteamDll = 'sdk\sdk\redistributable_bin\win64\steam_api64.dll'
$VcRuntime = @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')
$Root = Resolve-Path '..\..'
$Release = Join-Path $Root 'build\windows\x64\runner\Release'

if (-not (Test-Path $Builder)) { throw "No Steam uploader at $Builder; unzip the Steamworks SDK into infra\steam\sdk" }
if (-not (Test-Path $SteamDll)) { throw "No steam_api64.dll at $SteamDll" }

$Version = ((Get-Content (Join-Path $Root 'pubspec.yaml') | Select-String '^version:').Line -split '\s+')[1]
$Commit = (git rev-parse --short HEAD).Trim()
$Dirty = if (git status --porcelain -- (Join-Path $Root 'lib') (Join-Path $Root 'packages') (Join-Path $Root 'assets')) { '+local changes' } else { '' }

if (-not $SkipBuild) {
  Write-Host 'Building Windows...'
  # Launched outside Steam, a Steam build relaunches through it
  $defines = @('--dart-define=STEAM_RESTART=true')
  if ($AiText) { $defines += '--dart-define=AI_TEXT=true' }
  Push-Location $Root
  try {
    flutter build windows --release @defines
    if ($LASTEXITCODE -ne 0) { throw 'flutter build windows failed' }
  } finally { Pop-Location }
}

Remove-Item -Recurse -Force content -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force content\windows, output | Out-Null
Copy-Item -Recurse "$Release\*" content\windows
foreach ($needed in 'donut_game.exe', 'flutter_windows.dll', 'data') {
  if (-not (Test-Path "content\windows\$needed")) { throw "The Windows build has no $needed" }
}

# Flutter never clears old files out of Release, so DLLs from plugins the
# game no longer uses ride along; keep only the ones it lists now
$keep = @('flutter_windows.dll', 'steam_api64.dll') + $VcRuntime
$cmake = Get-Content (Join-Path $Root 'windows\flutter\generated_plugins.cmake')
$inList = $false
foreach ($line in $cmake) {
  if ($line -match 'FLUTTER_PLUGIN_LIST$') { $inList = $true; continue }
  if ($inList) {
    if ($line -match '\)') { $inList = $false; continue }
    $plugin = $line.Trim()
    if ($plugin) { $keep += "${plugin}_plugin.dll" }
  }
}
Get-ChildItem content\windows\*.dll | Where-Object { $keep -notcontains $_.Name } | ForEach-Object {
  Write-Host "Leaving out $($_.Name) (left over from an older build)"
  Remove-Item $_.FullName
}
# Valve's Steam library, which the game loads from beside its .exe
Copy-Item $SteamDll content\windows\
# Microsoft's C++ runtime, which Flutter needs and a fresh Windows lacks;
# Steam doesn't install it for Donut (nocommonredists), so it ships beside
# the .exe. From the 64-bit system folder, whichever PowerShell runs this.
$System = if ([Environment]::Is64BitProcess) { "$env:WINDIR\System32" } else { "$env:WINDIR\Sysnative" }
foreach ($dll in $VcRuntime) {
  if (-not (Test-Path "$System\$dll")) { throw "No $dll in $System; install the Visual C++ Redistributable (x64)" }
  Copy-Item "$System\$dll" content\windows\
}

$text = if ($AiText) { ', AI text' } else { '' }
$setLive = if ($Beta) { "  `"SetLive`" `"$Beta`"" } else { '' }
$previewFlag = if ($Preview) { '1' } else { '0' }
$vdf = @"
"AppBuild"
{
  "AppID" "$AppId"
  "Desc" "Donut $Version ($Commit$Dirty) Windows$text"
  "ContentRoot" "$((Resolve-Path content).Path)\"
  "BuildOutput" "$((Resolve-Path output).Path)\"
  "Preview" "$previewFlag"
$setLive
  "Depots"
  {
    "$WindowsDepot" { "FileMapping" { "LocalPath" "windows\*" "DepotPath" "." "Recursive" "1" } }
  }
}
"@
Set-Content -Encoding ascii app_build_windows.vdf $vdf

$live = if ($Beta) { ", live on $Beta" } else { '' }
$dry = if ($Preview) { ' (preview, nothing uploaded)' } else { '' }
Write-Host "Uploading Donut $Version ($Commit$Dirty$text) to app ${AppId}: Windows$live$dry"
& $Builder +login $Account +run_app_build (Resolve-Path app_build_windows.vdf).Path +quit
if ($LASTEXITCODE -ne 0) { throw "steamcmd exited with $LASTEXITCODE" }
