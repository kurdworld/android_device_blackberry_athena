# BlackBerry KEY2 source patches (LineageOS 24.0)

Some KEY2 fixes live outside this device tree, in source projects that LineageOS
ships unmodified. They are kept here as patch files so those projects stay as
`repo sync` leaves them and every change is reviewable and revertible.

Ported from the CalyxOS KEY2 patch set
(`calyxos/device/blackberry/athena/patches`), which targets the same LineageOS 24
code base and the same 4.19 kernel.

## Applying

Run this after every `repo sync` and before building:

```bash
cd ~/android/lineageos
device/blackberry/athena/patches/apply.sh
```

It is safe to run more than once: patches that are already applied are skipped.

| Command | What it does |
|---|---|
| `apply.sh` | Applies every patch |
| `apply.sh --check` | Shows each patch as APPLIED, CLEAN (not applied yet) or CONFLICT |
| `apply.sh --revert` | Removes every patch, returning the projects to stock LineageOS |

`repo sync` refuses to update a project that has local changes. Run
`apply.sh --revert` before syncing, then `apply.sh` again afterwards.

A CONFLICT means LineageOS changed that file. Revert the patches, sync, then
re-apply the change by hand and save it again with `git diff > <patch>` from the
project folder.

## Patches

| Folder | Patch | Fixes |
|---|---|---|
| `build/make` | `ota-non-dynamic-partitions` | Building OTA packages for the KEY2's fixed (non-dynamic) partitions |
| `frameworks/av` | `video-surface-switch` | Video in apps like X stalling for about 2 s whenever a video moves on screen (hardware decoder surface switch) |
| `frameworks/base` | `keyboard-pin-numeric-fields` | Setting a PIN (and dialling) on a keyboard without a digit row: numeric fields accept the digit printed on the Alt layer of a letter key, so W/E/R/S/D/F/Z/X/C type 1-9 |
| `frameworks/base` | `keyguard-keyboard-pin` | Lock screen: the PIN bouncer accepts the same Alt-layer digits, and a PIN digit typed while the screen is off wakes the device and is delivered to the keyguard |
| `frameworks/hardware/interfaces` | `displayservice-hal` | Flashlight and camera (display service interface the camera HAL needs) |
| `frameworks/native` | `keyboard-touchpad` | Keyboard touch surface handled as a touchpad instead of taps on the screen; keeps the KEY2 character map when a keyboard layout overlay is set |
| `frameworks/opt/telephony` | `no-radio-config-wait` | Settings freezing for 2 s on pages that query the radio |
| `packages/apps/Launcher3` | `no-navbar-flash-at-boot` | Navigation bar flashing during boot |
| `packages/inputmethods/LatinIME` | `0001-fix-german-qwertz` | German QWERTZ subtype missing from the keyboard picker |
| `system/tools/hidl` | `allow-displayservice` | Flashlight and camera (allows the display service interface; pairs with `displayservice-hal`) |
| `system/zygote` | `old-kernel-capabilities` | Brave and Chromium tabs crashing on the 4.19 kernel |

## Deliberately not ported

| CalyxOS patch | Reason |
|---|---|
| `frameworks/base/blackberry-keyboard-and-hardware` | LineageOS already has most of it (volume wake, Home/Menu/App switch actions, partial screenshot, `FLAG_LONG_SWIPE`); the remaining BlackBerry-specific parts need a hand-written LineageOS port, not a straight apply. Only the PIN-entry parts are carried over, as `keyboard-pin-numeric-fields` and `keyguard-keyboard-pin`; the helper that queues digits typed before the bouncer appears is not ported |
| `hardware/qcom-caf/sdm660/display-namespace-imports` | LineageOS' `hardware/qcom-caf/sdm660/Android.bp` already declares the same `soong_namespace` imports |
| `calyx-sdk/open-app-action` | CalyxOS SDK only, no LineageOS counterpart |
| `packages/apps/CalyxParts/hardware-key-options` | CalyxParts only; LineageParts would need a separate port |
| `packages/apps/Updater/download-url` | CalyxOS update server only |
| `vendor/calyx/custom-version` | CalyxOS vendor only |
| `qwertz_fix.patch` | Meta patch that edits the LatinIME patch above; not applicable |

## Known limitation

`keyboard-touchpad` is only the inputflinger half of the touchpad work. The
scrolling conversion itself (`ViewRootImpl.SyntheticTouchKeypadHandler` and
`View.getTouchKeypadDeviceId`) lives in `frameworks/base`, which is currently
left untouched. Without it the keyboard surface behaves as a pointer instead of
scrolling, so this patch may need to be reverted if it regresses input.
