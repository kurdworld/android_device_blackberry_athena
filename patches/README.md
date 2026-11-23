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
| `frameworks/base` | `blackberry-hardware-key-remap` | Running the Sym, Function and Convenience key short, long and double press actions chosen in System > Buttons: Ctrl and right Meta (Super) held from key-down, Tab tapped on release, custom apps launched, and Default falling back to the key's native behaviour; when a distinct double-press action is set, the short-press action waits for the double-tap timeout so a double press runs only the double-press action |
| `frameworks/base` | `blackberry-super-key` | The Function key's Super action working as a modifier: the injected right Meta modifier reaches the focused app instead of being consumed as an unhandled Meta shortcut, while system Meta shortcuts still work; a bare Super tap falls back to the launcher's all apps activity when no accessibility all apps action is registered |
| `frameworks/base` | `keyboard-pin-numeric-fields` | Setting a PIN (and dialling) on a keyboard without a digit row: numeric fields accept the digit printed on the Alt layer of a letter key, so W/E/R/S/D/F/Z/X/C type 1-9 |
| `frameworks/base` | `keyguard-keyboard-pin` | Lock screen: the PIN bouncer accepts the same Alt-layer digits, and a PIN digit typed while the screen is off wakes the device and is delivered to the keyguard. The setting and key character map are cached instead of queried on every key press, which made PIN entry lag |
| `frameworks/base` | `keyguard-keyboard-pin-bouncer` | Typing a PIN digit on the keyboard brings up the PIN bouncer and enters the digit, without swiping first; digits typed before the bouncer is ready are queued |
| `frameworks/base` | `keyguard-pin-privacy-performance` | PIN entry lagging with "Enhanced PIN privacy": the dot and field width snap instead of running a 320 ms animation for every key |
| `frameworks/base` | `keyguard-biometric-haptic` | Fingerprint unlock/reject vibration always uses the KEY2's full-strength biometric haptic constants instead of the weak MSDL tokens |
| `frameworks/base` | `ime-switcher-shortcut` | Alt+Enter (or Shift+Space, Ctrl, SYM, as configured) opening the input method picker on the hardware keyboard; keeps the KEY2's own Alt/Sym character map when a layout overlay is set |
| `frameworks/base` | `notification-led-preview` | Notification LED colour picker showing nothing: the forced-on preview is checked before the "user is present" test, so the LED lights while the screen is on |
| `frameworks/base` | `power-keyboard-backlight-static` | Physical keyboard backlight flickering while the screen brightness changes (car charger/Android Auto): honour `keyboard_adaptive_brightness` and use the fixed keyboard brightness when it is off |
| `frameworks/base` | `power-navbutton-backlight-static` | Capacitive navigation key backlight flickering while windows come and go (Bluetooth/Android Auto): honour `button_adaptive_brightness` and use the fixed button brightness when it is off |
| `frameworks/base` | `double-press-power-custom-app` | Launching a user-picked app when the power button is pressed twice |
| `frameworks/base` | `expressive-settings-spacing` | Settings/System preference rows using the expressive design taking too much vertical space: 64dp minimum height, 10dp vertical text padding and tighter category spacing instead of 72dp/16dp |
| `frameworks/base` | `hardware-keys-custom-app` | System > Buttons "Custom app" action launching the app chosen for that specific button trigger |
| `frameworks/base` | `voip-call-media-pause` | Music continuing over the car's Bluetooth call audio during a VoIP call such as WhatsApp: media playback is paused when the audio mode changes to call or in-communication, and the paused session resumes when the call ends |
| `frameworks/hardware/interfaces` | `displayservice-hal` | Flashlight and camera (display service interface the camera HAL needs) |
| `frameworks/native` | `key-remap-physical-keyboard` | Key remapping being ignored for non-alphabetic physical keyboards such as the Convenience key (gpio-keys); remaps now apply to every physical keyboard |
| `frameworks/native` | `keyboard-touchpad` | Keyboard touch surface handled as a touchpad instead of taps on the screen; keeps the KEY2 character map when a keyboard layout overlay is set |
| `frameworks/opt/telephony` | `no-radio-config-wait` | Settings freezing for 2 s on pages that query the radio |
| `lineage-sdk` | `hardware-keys-custom-app` | Custom app button action value, the per-trigger settings that hold each trigger's app, their settings validators, and the per-gesture settings and legacy fallback for the KEY2's Sym, Function and Convenience keys |
| `packages/apps/Launcher3` | `no-navbar-flash-at-boot` | Navigation bar flashing during boot |
| `packages/apps/LineageParts` | `flashlight-power-key-entry` | The long-press-power torch entry missing from System > Buttons: fall back to the platform flash feature when the camera service cannot report a back flash |
| `packages/apps/LineageParts` | `hardware-keys-custom-app` | Per-trigger Custom app action in System > Buttons: choosing it opens an icon app picker and the summary shows "Custom App: <app>"; on the KEY2 it also adds the Sym, Function and Convenience key categories, with Short/Long/Double press for Sym and Convenience and a single action for Function (Default, Ctrl, Tab, Super key or Custom app), the Convenience key wake toggle, and migrates the old Settings > Keyboard values |
| `packages/apps/Settings` | `remove-lift-to-check` | Removing Lift to check phone from Display |
| `packages/apps/Settings` | `remove-one-handed-mode` | Removing One-handed mode from System > Gestures and Accessibility |
| `packages/apps/Settings` | `remove-circle-to-search` | Removing the Circle to Search switch from System (MindTheGapps declares the contextual search feature, so it always appeared) |
| `packages/apps/Settings` | `double-tap-power-custom-app` | Replacing the Wallet target of System > Gestures > Double press power button with a Custom app target that opens an icon app picker matching System > Buttons |
| `packages/apps/Settings` | `expressive-settings-spacing` | The top-level Settings items using the expressive design taking too much vertical space: 64dp minimum height and 10dp vertical text padding instead of 72dp/16dp |
| `packages/apps/Settings` | `physical-keyboard-settings` | Physical keyboard layout override in Settings > Keyboard; the Sym, Function and Convenience key actions now live in System > Buttons |
| `packages/apps/Updater` | `updater-changelog-url` | System update > Recent changes opens the styled `lineageos_ota` repository `changelog.html` (https://github.com/kurdworld/lineageos_ota/blob/main/changelog.html) instead of the generic download.lineageos.org device changes page |
| `packages/inputmethods/LatinIME` | `0001-fix-german-qwertz` | German QWERTZ subtype missing from the keyboard picker |
| `system/sepolicy` | `releasekey-for-mac-permissions` | Release builds failing because SELinux `mac_permissions.xml` generation looked for `testkey.x509.pem` next to the private release keys; it now uses `releasekey.x509.pem` |
| `system/tools/hidl` | `allow-displayservice` | Flashlight and camera (allows the display service interface; pairs with `displayservice-hal`) |
| `system/zygote` | `old-kernel-capabilities` | Brave and Chromium tabs crashing on the 4.19 kernel |

## Deliberately not ported

| CalyxOS patch | Reason |
|---|---|
| `frameworks/base/blackberry-keyboard-and-hardware` | LineageOS already has most of it (volume wake, Home/Menu/App switch actions, partial screenshot, `FLAG_LONG_SWIPE`); the remaining BlackBerry-specific parts need a hand-written LineageOS port, not a straight apply. The PIN-entry, PIN-bouncer queue, IME-switcher, biometric-haptic and notification-LED-preview parts are carried over as separate patches; the keyboard touchpad part is not |
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
