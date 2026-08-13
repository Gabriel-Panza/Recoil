# Recoil Steamworks setup

The project uses GodotSteam GDExtension 4.18.1, built for Godot 4.6.2 and Steamworks SDK 1.64. Steam remains optional at runtime: Web and non-Steam desktop builds continue using local achievements and `user://progress.cfg`.

## Local Steam test

1. Copy `steamworks/steam_appid.txt.example` to `steam_appid.txt` in the project root.
2. Replace `480` with the Recoil App ID when it exists. App ID 480 is only Valve's Spacewar test application.
3. Start the Steam client before running the game.
4. Do not ship or commit `steam_appid.txt`. A game launched by Steam receives its App ID from the client.

`AchievementManager.get_steam_diagnostics()` reports extension availability, initialization status, stats readiness and Cloud availability. The Steam overlay may not work inside the editor; validate it from an exported build launched by Steam.

## Achievements and stats

Create all API names listed in `AchievementManager.DEFINITIONS` in Steamworks. Set achievements to client-set and use the same Hidden value as the local definition. Localized names and descriptions already exist in `Scripts/General/i18n.gd` for English and Brazilian Portuguese.

Create these integer client stats before publishing the achievement configuration:

| Stat API name | Maximum / unlock value | Progress achievement |
| --- | ---: | --- |
| `STAT_CONTRACT_STREAK` | 7 | `ACH_READ_FINE_PRINT` |
| `STAT_ENDLESS_BOSSES` | 8 | `ACH_EIGHTH_SIN` |
| `STAT_RETIRED_SCORE` | 10000 | `ACH_EXECUTIVE_DECISION` |
| `STAT_STORY_ARMS_COMPLETED` | 3 | `ACH_ARSENAL_OF_PENANCE` |

Publish the Steamworks achievement changes before testing. The game merges local and Steam progress by maximum value and never clears an unlocked achievement.

## Steam Cloud

Enable Steam Auto-Cloud and synchronize only `progress.cfg`:

| OS | Root | Subdirectory | Pattern |
| --- | --- | --- | --- |
| Windows | `WinAppDataRoaming` | `Godot/app_userdata/Recoil` | `progress.cfg` |
| Linux / Steam Deck | `LinuxXdgDataHome` | `godot/app_userdata/Recoil` | `progress.cfg` |

Apply the Linux root override so both entries represent the same cross-platform file. A quota of 1 MB and 10 files is ample. Do not synchronize `settings.cfg`, because resolution and input mappings are machine-specific.

## SteamPipe

In Steamworks, create one Windows depot and one Linux depot, publish those changes and add both depots to the Developer Comp and store packages. Configure launch options as:

| OS | Executable |
| --- | --- |
| Windows | `windows/Recoil.exe` |
| Linux | `linux/Recoil.x86_64` |

Prepare exports and VDF files without uploading:

```powershell
powershell -ExecutionPolicy Bypass -File .\steamworks\scripts\build_steam.ps1 -AppId 1234560 -WindowsDepotId 1234561 -LinuxDepotId 1234562
```

Build local test folders with a temporary App ID file:

```powershell
powershell -ExecutionPolicy Bypass -File .\steamworks\scripts\build_steam.ps1 -AppId 480 -WindowsDepotId 4801 -LinuxDepotId 4802 -LocalTestAppId 480
```

Upload through the Steamworks SDK's `steamcmd.exe`. The script never accepts or stores a password; SteamCMD requests the password and Steam Guard interactively:

```powershell
powershell -ExecutionPolicy Bypass -File .\steamworks\scripts\build_steam.ps1 `
  -AppId 1234560 `
  -WindowsDepotId 1234561 `
  -LinuxDepotId 1234562 `
  -SteamCmdPath "C:\SteamworksSDK\tools\ContentBuilder\builder\steamcmd.exe" `
  -SteamAccount "recoil_build" `
  -SetLive "internal" `
  -Upload
```

The generated VDF files, exported content and SteamPipe logs remain ignored by Git. Never use `-SetLive default`; promote a tested build to the default branch through Steamworks.

The pipeline also copies `THIRD_PARTY_NOTICES.txt` beside both executables. Add the exact source and license for every third-party audio asset to the release credits before publishing.
