# Changelog — BlackBerry KEY2 (athena)

LineageOS 24.0 port for the BlackBerry KEY2 (SDM660). This lists what the port
adds or changes on top of the LineageOS baseline.

## New features

### Notification LED
- The colour picker previews the chosen colour with the screen on.

### Power button
- "Long press for torch" is available again in System > Buttons > Power button.
- Double press can launch any installed app, not just Camera or Wallet.
- System > Gestures > Double press power button > Custom app opens the app picker straight away; the separate App row is gone.
- The Custom app row shows the chosen app's name.

### Diagnostics
- BlackBerry Settings > Troubleshooting > Collect logs produces a bug report.

### Keyboard and lock screen
- Typing the PIN on the physical keyboard opens the lock screen bouncer.
- Alt+Enter, Shift+Space, Ctrl and SYM switch input methods as configured.

### Button remapping
- "Custom app" is a new action in System > Buttons; choosing it opens the app picker straight away.
- Every button trigger keeps its own custom app, so changing one does not affect the others.
- The trigger summary shows the chosen app as "Custom App: <app>".
- Custom app pickers use the same icon rows everywhere: System > Buttons, Settings > Keyboard and the double-press power gesture.
- The separate "Custom app action" section and the Buttons double-press power rows are gone.
- The Function key has a single Action row instead of separate short, long and double press rows; it offers Default, Ctrl, Tab, Super key and Custom app.
- The old Function long-press choice is carried over to the single action automatically, and Function long and double presses follow the selected action.

### Physical keyboard
- Settings > Keyboard > Physical keyboard layout selects QWERTY, AZERTY or QWERTZ instead of the detected layout.
- The layout is stored in Secure settings, so it applies immediately and survives reboots.
- Settings > Keyboard > Hardware keys remaps Sym, Function and Convenience to Ctrl, Tab, Super or any installed app.
- The Function key uses one action, while Sym and Convenience keep short, long and double press actions.
- Each key stores its own custom app, so the three keys can launch three different apps.
- The extra Sym and Convenience key app rows are gone; choosing Custom app on either key opens the app picker directly.
- The Function key is delivered as Ctrl Right, so Ctrl remaps work in apps that only accept a real Ctrl.
- The Function key's Super action works as a held modifier, so Super + key combinations reach the focused app.

## Fixes

### Boot
- Precompiled odex/vdex stay in `system.img`, so SystemUI, Settings and Launcher no longer run from the APK.
- `ro.cp_system_other_odex` removed, so the first boot no longer waits for a non-existent `system_other`.
- Both CPU clusters run at `performance` with `mq-deadline` and 512 KB read-ahead until boot completes, then return to `schedutil` and 128 KB read-ahead.
- Per-node, per-permission and per-attribute shell forks removed from the init scripts.
- ueventd nodes created from init and the ION label fixed, so graphics come up on the first boot.
- Unused console shell and the leftover `loggy` logger no longer run during boot.

### Display
- Stock font and density defaults instead of the 1.15 scale and 380 dpi.
- The virtual navigation bar no longer flashes during boot.
- Moving a video on screen no longer stalls playback for about 2 s.
- Background blur is available behind Quick Settings, the notification shade and recents; it can be turned off in Settings > Accessibility > Color and motion.

### Performance
- Pressing Recents or opening Quick Settings now starts at a boosted CPU frequency instead of ramping up from idle, matching the CalyxOS input boost.
- schedutil changes frequency without a rate limit and WALT rotates heavy tasks onto the big cluster, matching CalyxOS.
- zram selects lz4 explicitly, swappiness is 100 and `vfs_cache_pressure` is 50, so the launcher and recents tasks stay resident like on CalyxOS. zram stays at 2.5 GB (CalyxOS uses 2 GB), which is only extra headroom.
- Dirty pages are flushed earlier and in smaller batches (5% background, 2 s expiry), so installs, downloads and photo sync no longer stall the eMMC for seconds.
- dm-crypt volumes are marked non-rotational, so the block layer does not apply seek heuristics to flash.
- LPM retention is disabled, so the first frame after the screen turns on is no longer delayed by about a second.
- The extra frame buffer is removed, lowering input-to-display latency.

### Audio
- A USB-C headset plugged in during a call now moves the call audio to it.
- A wired headset with mic maps to a real `voice-headset` mixer path instead of a missing one.
- Ring and notification volume curves reach a usable low level.
- Music no longer plays over the car's Bluetooth call audio during a VoIP call such as WhatsApp: media sessions are paused when the audio mode changes to call or in-communication, and only the sessions paused by this code are resumed when the call ends. Muting and audio-focus locking are not used, so call ringtones and unrelated apps are unaffected.

### Camera and fingerprint
- The camera HAL loads again, so the camera and the torch work.
- `/data/goodix` is created with the right SELinux rules and fingerprint recognition is stable.

### Connectivity
- Mobile data works without Wi-Fi, as the IWLAN poll no longer stalls at `POWER_OFF`.

### Kernel
- Updated the 4.19 kernel from `4.19.325-cip128` to `4.19.325-cip137` with a fresh three-way merge, preserving every KEY2/Android porter fix and CIP security fix instead of replacing conflicted files wholesale.
- Version strings now report `4.19.325-cip137-st21`, so the Wi-Fi module is rebuilt with matching vermagic.
- Added a 4.19 compatibility alias `timer_delete_sync()` → `del_timer_sync()` so newer CIP backports compile on this tree.
- F2FS: kept the porter `f2fs_err`/`f2fs_info` logging API, extent-cache and iostat changes while taking CIP's read-only recovery, orphan-entry validation and writeback ordering fixes; the new orphan-entry error uses the local logging API.
- Networking: kept the local LWT BPF headroom crash fix while taking CIP's `LL_RESERVED_SPACE()` sizing, plus CIP fixes in BPF tail-call attach types, connlimit, nf_conncount, IPv6 fib dumps, QRTR and rmnet.
- ALSA compress offload: kept the porter non-blocking drain/partial-drain rework and exported `snd_compress_free()` while dropping the unused legacy registration API.
- DVB: restored CIP's `dvb_ringbuffer_reset()` on reopen so the ring buffer waitqueue is not reinitialised while in use.
- Preserved local Wi-Fi fixes in `ce_main.c`/`htt_h2t.c`, the `ibmpex.c` NULL-check/cleanup fix, Android HID/USB-gadget/MMC/QCOM fixes, and the ARM64 CPU-errata MIDR lists alongside CIP's repeat-TLBI list.

### Keyboard
- Layout overlays no longer replace the built-in Alt/Sym character map.
- German QWERTZ mapping corrected.

### Hardware keys
- Ctrl and Tab remaps now also apply to the Convenience key.
- Home launcher is no longer offered for the Sym, Function or Convenience key.

### Lock screen
- PIN entry no longer queries Settings and `KeyCharacterMap` on every key press.
- Hidden PIN text no longer runs two animators per keystroke.
- Fingerprint unlock and reject haptics always use the device's full-strength biometric constants instead of the weak MSDL tokens.

### Haptics
- Physical key and button feedback uses full-amplitude waveforms for long press, virtual key, keyboard tap, context click, confirm/reject and power long-press.
- Fingerprint unlock uses a longer full-strength pulse and the reject pattern is longer, so the motor has time to spin up and the vibration is clearly felt.

### Settings and backlight
- Lift to check phone, one-handed mode and Circle to Search are no longer exposed.
- Choosing a custom app in System > Buttons no longer crashes Settings; the per-trigger app settings are now registered with the settings provider.
- The double-press power gesture no longer opens the stock app list or shows a separate App entry; it uses the same icon picker as the other button pickers.
- Navigation key and keyboard backlight stay static when adaptive brightness is off.
- Settings rows use a 60dp height with 8dp text padding, so the root page and every submenu are a little more compact without feeling cramped.
- `mq-deadline` with 128 KB read-ahead after boot reduces Settings scrolling jank.

### Updater
- System update > Recent changes opens the `lineageos_ota` repository's styled `changelog.html` changelog at `https://github.com/kurdworld/lineageos_ota/blob/main/changelog.html` instead of the generic download.lineageos.org device changes page.

### Security and certification
- Builds are signed with dedicated kurdworld/LineageOS release keys. Private keys live only in the owner-only `$HOME/.lineageos-keys` store and are linked locally as `vendor/lineage-priv/keys`; AOSP test keys, development keys and keys from other projects are not used.
- Build user and host are fixed to `kurdworld`/`lineageos`, so the local account never appears in build properties or fingerprints.
- The build and publish scripts refuse test-key output; the publisher checks the OTA certificate before touching the feed.
- SELinux `mac_permissions.xml` generation uses the kurdworld `releasekey` certificate instead of a missing AOSP `testkey` path, so release builds no longer need any test key in the private key store.
- SELinux stays enforcing with rules for diagnostics, camera, LED, fingerprint and storage.
- The device passes Play certification with the new CTS overlay.
