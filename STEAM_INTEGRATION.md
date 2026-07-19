# Steam integration

The game owns achievement progress locally. Steam is an optional backend detected at runtime through the `Steam` engine singleton, which keeps non-Steam and Web builds functional.

## GodotSteam

1. Install a Godot 4 compatible GodotSteam GDExtension.
2. Use the production Steam App ID in the export setup and `steam_appid.txt` only for local development.
3. Register every `steam_id` and non-empty `stat_id` from `Scripts/General/achievement_manager.gd` in Steamworks.
4. Configure names, descriptions, locked icons, unlocked icons, localization and the Hidden flag in Steamworks.
5. Publish the Steamworks configuration before testing.

The manager initializes Steam when the singleton exists, requests current stats, merges remote and local unlocks, sends progress stats, calls `SetAchievement`, and stores stats. Unlock synchronization is a union: an unlocked achievement is never removed locally or remotely.

## Steam Cloud

Persistent progression is stored in `user://progress.cfg`. It contains Story completion, Codex discoveries, achievement unlocks and achievement progress. Configure Steam Auto-Cloud to synchronize that file from Godot's app userdata directory for Windows and Linux/Steam Deck.

Do not cloud-sync `settings.cfg` by default. Resolution, fullscreen mode and input mappings are machine-specific and may be unsuitable when moving between a desktop and Steam Deck.

Cloud availability is exposed through `AchievementManager.is_steam_cloud_available()`. Steam Cloud still needs to be enabled for the app and the Auto-Cloud paths must be configured in the Steamworks partner panel.

Recommended Auto-Cloud entries for the Godot project name `Recoil`:

- Windows: root `WinAppDataRoaming`, subdirectory `Godot/app_userdata/Recoil`, pattern `progress.cfg`.
- Linux and Steam Deck: root `LinuxXdgDataHome`, subdirectory `godot/app_userdata/Recoil`, pattern `progress.cfg`.
- Mark the root for all operating systems and configure the Linux root override so the same save is shared between Windows and Steam Deck.

Use a small quota (for example 1 MB and 10 files), publish the Cloud configuration, and test with `testappcloudpaths <AppId>` in the Steam client console. Auto-Cloud uploads on game exit and downloads before launch, so no platform-specific file API is needed in gameplay code.

## Achievement API names

Create one client-set Steam achievement for every `steam_id` in `AchievementManager.DEFINITIONS`. Create these integer stats for progress achievements:

- `STAT_CONTRACT_STREAK`, unlock value 7, progress achievement `ACH_READ_FINE_PRINT`.
- `STAT_ENDLESS_BOSSES`, unlock value 8, progress achievement `ACH_EIGHTH_SIN`.
- `STAT_RETIRED_SCORE`, unlock value 10000, progress achievement `ACH_EXECUTIVE_DECISION`.
- `STAT_STORY_ARMS_COMPLETED`, unlock value 3, progress achievement `ACH_ARSENAL_OF_PENANCE`.

The local manager and Steam use a maximum-value merge. An unlock from either side is copied to the other side; achievements are never cleared by synchronization.
