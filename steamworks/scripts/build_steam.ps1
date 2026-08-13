[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[ValidateRange(1, [uint32]::MaxValue)]
	[uint32]$AppId,

	[Parameter(Mandatory = $true)]
	[ValidateRange(1, [uint32]::MaxValue)]
	[uint32]$WindowsDepotId,

	[Parameter(Mandatory = $true)]
	[ValidateRange(1, [uint32]::MaxValue)]
	[uint32]$LinuxDepotId,

	[string]$GodotExecutable = "godot",
	[string]$SteamCmdPath = "",
	[string]$SteamAccount = "",
	[string]$SetLive = "",
	[string]$Description = "Recoil automated build",
	[uint32]$LocalTestAppId = 0,
	[switch]$SkipExport,
	[switch]$Preview,
	[switch]$Upload
)

$ErrorActionPreference = "Stop"
$steamworksRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$projectRoot = (Resolve-Path (Join-Path $steamworksRoot "..")).Path
$contentRoot = Join-Path $steamworksRoot "content"
$generatedRoot = Join-Path $steamworksRoot "generated"
$outputRoot = Join-Path $steamworksRoot "output"
$templatesRoot = Join-Path $steamworksRoot "templates"

function Reset-BuildDirectory {
	param([Parameter(Mandatory = $true)][string]$Path)

	$resolvedPath = [System.IO.Path]::GetFullPath($Path)
	$allowedRoot = [System.IO.Path]::GetFullPath($contentRoot)
	if (-not $resolvedPath.StartsWith($allowedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
		throw "Refusing to reset a directory outside $allowedRoot"
	}
	if (Test-Path -LiteralPath $resolvedPath) {
		Remove-Item -LiteralPath $resolvedPath -Recurse -Force
	}
	New-Item -ItemType Directory -Path $resolvedPath -Force | Out-Null
}

function Invoke-GodotExport {
	param(
		[Parameter(Mandatory = $true)][string]$Preset,
		[Parameter(Mandatory = $true)][string]$Destination
	)

	$godotCommand = Get-Command $GodotExecutable -ErrorAction Stop
	$arguments = @(
		"--headless",
		"--path", "`"$projectRoot`"",
		"--export-release", "`"$Preset`"",
		"`"$Destination`""
	)
	$process = Start-Process -FilePath $godotCommand.Source -ArgumentList $arguments -NoNewWindow -Wait -PassThru
	if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
		throw "Godot export failed for preset '$Preset' with exit code $($process.ExitCode). Expected artifact: $Destination"
	}
}

function Expand-VdfTemplate {
	param(
		[Parameter(Mandatory = $true)][string]$TemplatePath,
		[Parameter(Mandatory = $true)][string]$DestinationPath,
		[Parameter(Mandatory = $true)][hashtable]$Values
	)

	$content = Get-Content -LiteralPath $TemplatePath -Raw
	foreach ($key in $Values.Keys) {
		$content = $content.Replace("@@$key@@", [string]$Values[$key])
	}
	if ($content -match "@@[A-Z_]+@@") {
		throw "Unresolved template token in $TemplatePath"
	}
	Set-Content -LiteralPath $DestinationPath -Value $content -Encoding ASCII
}

$windowsRoot = Join-Path $contentRoot "windows"
$linuxRoot = Join-Path $contentRoot "linux"
$windowsExecutable = Join-Path $windowsRoot "Recoil.exe"
$linuxExecutable = Join-Path $linuxRoot "Recoil.x86_64"

if (-not $SkipExport) {
	Reset-BuildDirectory -Path $windowsRoot
	Reset-BuildDirectory -Path $linuxRoot
	Invoke-GodotExport -Preset "Windows Desktop" -Destination $windowsExecutable
	Invoke-GodotExport -Preset "Linux" -Destination $linuxExecutable
}

$noticesSource = Join-Path $projectRoot "THIRD_PARTY_NOTICES.txt"
$windowsNotices = Join-Path $windowsRoot "THIRD_PARTY_NOTICES.txt"
$linuxNotices = Join-Path $linuxRoot "THIRD_PARTY_NOTICES.txt"
if (-not (Test-Path -LiteralPath $noticesSource -PathType Leaf)) {
	throw "Third-party notices file is missing: $noticesSource"
}
Copy-Item -LiteralPath $noticesSource -Destination $windowsNotices -Force
Copy-Item -LiteralPath $noticesSource -Destination $linuxNotices -Force

$requiredFiles = @(
	$windowsExecutable,
	(Join-Path $windowsRoot "steam_api64.dll"),
	(Join-Path $windowsRoot "libgodotsteam.windows.template_release.x86_64.dll"),
	$windowsNotices,
	$linuxExecutable,
	(Join-Path $linuxRoot "libsteam_api.so"),
	(Join-Path $linuxRoot "libgodotsteam.linux.template_release.x86_64.so"),
	$linuxNotices
)
foreach ($requiredFile in $requiredFiles) {
	if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
		throw "Required Steam build file is missing: $requiredFile"
	}
}

if ($Upload -and $LocalTestAppId -ne 0) {
	throw "LocalTestAppId cannot be used together with Upload. steam_appid.txt must not ship in Steam depots."
}
if ($SetLive -and $SetLive -notmatch "^[A-Za-z0-9_-]+$") {
	throw "SetLive may only contain letters, numbers, underscores and hyphens."
}
if ($Description.Contains('"')) {
	throw "Description cannot contain double quotes."
}
if ($LocalTestAppId -ne 0) {
	Set-Content -LiteralPath (Join-Path $windowsRoot "steam_appid.txt") -Value $LocalTestAppId -Encoding ASCII
	Set-Content -LiteralPath (Join-Path $linuxRoot "steam_appid.txt") -Value $LocalTestAppId -Encoding ASCII
} else {
	Remove-Item -LiteralPath (Join-Path $windowsRoot "steam_appid.txt") -Force -ErrorAction SilentlyContinue
	Remove-Item -LiteralPath (Join-Path $linuxRoot "steam_appid.txt") -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType Directory -Path $generatedRoot -Force | Out-Null
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

$windowsDepotScript = Join-Path $generatedRoot "depot_windows_$WindowsDepotId.vdf"
$linuxDepotScript = Join-Path $generatedRoot "depot_linux_$LinuxDepotId.vdf"
$appBuildScript = Join-Path $generatedRoot "app_build_$AppId.vdf"
$escapedContentRoot = $contentRoot.Replace("\", "\\")
$escapedOutputRoot = $outputRoot.Replace("\", "\\")

Expand-VdfTemplate -TemplatePath (Join-Path $templatesRoot "depot_windows.vdf.template") -DestinationPath $windowsDepotScript -Values @{
	DEPOT_ID = $WindowsDepotId
	CONTENT_ROOT = $escapedContentRoot
}
Expand-VdfTemplate -TemplatePath (Join-Path $templatesRoot "depot_linux.vdf.template") -DestinationPath $linuxDepotScript -Values @{
	DEPOT_ID = $LinuxDepotId
	CONTENT_ROOT = $escapedContentRoot
}
Expand-VdfTemplate -TemplatePath (Join-Path $templatesRoot "app_build.vdf.template") -DestinationPath $appBuildScript -Values @{
	APP_ID = $AppId
	DESCRIPTION = "$Description $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
	CONTENT_ROOT = $escapedContentRoot
	BUILD_OUTPUT = $escapedOutputRoot
	PREVIEW = if ($Preview) { '"Preview" "1"' } else { '' }
	SET_LIVE = if ($SetLive) { '"SetLive" "' + $SetLive + '"' } else { '' }
	WINDOWS_DEPOT_ID = $WindowsDepotId
	LINUX_DEPOT_ID = $LinuxDepotId
	WINDOWS_DEPOT_SCRIPT = $windowsDepotScript.Replace("\", "\\")
	LINUX_DEPOT_SCRIPT = $linuxDepotScript.Replace("\", "\\")
}

Write-Host "Steam content prepared in: $contentRoot"
Write-Host "SteamPipe app build script: $appBuildScript"

if ($Upload) {
	if (-not $SteamCmdPath -or -not (Test-Path -LiteralPath $SteamCmdPath -PathType Leaf)) {
		throw "Upload requires a valid -SteamCmdPath."
	}
	if (-not $SteamAccount) {
		throw "Upload requires -SteamAccount. Password and Steam Guard remain interactive."
	}
	if ($SetLive -eq "default") {
		throw "SteamPipe cannot automatically set the default branch live. Leave SetLive empty or use a beta branch."
	}
	& $SteamCmdPath +login $SteamAccount +run_app_build $appBuildScript +quit
	$commandSucceeded = $?
	$exitCode = $LASTEXITCODE
	if (-not $commandSucceeded -or ($null -ne $exitCode -and $exitCode -ne 0)) {
		throw "SteamPipe upload failed with exit code $exitCode. Check logs in $outputRoot"
	}
}
