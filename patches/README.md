# CalyxOS source patches

Some KEY2 fixes need small changes to CalyxOS (and one LineageOS) source folders. They are kept here as patch files, so those folders stay exactly as CalyxOS ships them and every change lives in this repository.

## Applying

Run this after every `repo sync` and before building:

```bash
cd ~/android/calyxos
device/blackberry/athena/patches/apply.sh
```

It is safe to run more than once: patches that are already applied are skipped.

| Command | What it does |
|---|---|
| `apply.sh` | Applies every patch |
| `apply.sh --check` | Shows each patch as APPLIED, CLEAN (not applied yet) or CONFLICT |
| `apply.sh --revert` | Removes every patch, returning the folders to stock CalyxOS |

`repo sync` refuses to update a folder that has local changes. Run `apply.sh --revert` before syncing, then `apply.sh` again afterwards.

A CONFLICT means CalyxOS changed that file. Revert the patches, sync, then re-apply the change by hand and save it again with `git diff > <patch>` from the project folder.

## Patches

| Folder | Patch | Fixes |
|---|---|---|
| `build/make` | `ota-non-dynamic-partitions` | Building OTA packages for the KEY2's fixed (non-dynamic) partitions |
| `frameworks/av` | `video-surface-switch` | Video in apps like X stalling for about 2 s whenever a video moves on screen (hardware decoder surface switch) |
| `frameworks/base` | `blackberry-keyboard-and-hardware` | Keyboard symbols and layout, IME switcher shortcut, keyboard touchpad and scrolling, keyboard PIN entry, keyboard and button backlight, notification LED preview, button vibration, fingerprint unlock vibration, Home/Back/App switch button actions |
| `frameworks/hardware/interfaces` | `displayservice-hal`  | Flashlight and camera (display service interface the camera HAL needs) |
| `frameworks/native` | `keyboard-touchpad` | Keyboard touchpad and scrolling |
| `frameworks/opt/telephony` | `no-radio-config-wait` | Settings freezing for 2 s on pages that query the radio |
| `hardware/qcom-caf/sdm660` | `display-namespace-imports` | Display HAL build (LineageOS repository) |
| `packages/apps/CalyxParts` | `hardware-key-options` | Search/Assistant, Home, Back and App switch button options in Buttons settings |
| `packages/apps/Launcher3` | `no-navbar-flash-at-boot` | Navigation bar flashing during boot |
| `packages/apps/Updater` | `download-url` | Over-the-air updates: downloads each update zip from its own GitHub release, while the version file comes from the updates repository |
| `system/tools/hidl` | `allow-displayservice` | Flashlight and camera (allows the display service interface; pairs with `displayservice-hal`) |
| `system/zygote` | `old-kernel-capabilities` | Brave and Chromium tabs crashing on the 4.19 kernel |

Apply them before every build. Without the two display service patches the build stops, because the camera HAL's interface library no longer exists. Without the others, the fixes in the table are missing.

