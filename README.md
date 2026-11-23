# BlackBerry KEY2 (athena) — LineageOS 24.0

LineageOS 24.0 device tree for the BlackBerry KEY2 (SDM660). This lists what the
port adds or fixes on top of the LineageOS baseline.

Fixes that live outside this tree are kept as patch files under
[`patches/`](patches/) and applied with `patches/apply.sh` after every
`repo sync`.

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

### Physical keyboard
- Settings > Keyboard > Physical keyboard layout selects QWERTY, AZERTY or QWERTZ instead of the detected layout.
- The layout is stored in Secure settings, so it applies immediately and survives reboots.
- Settings > Keyboard > Hardware keys remaps Sym, Function and Convenience to Ctrl, Tab or any installed app.
- Each key stores its own custom app, so the three keys can launch three different apps.
- The extra Sym and Convenience key app rows are gone; choosing Custom app on either key opens the app picker directly.
- The Function key is delivered as Ctrl Right, so Ctrl remaps work in apps that only accept a real Ctrl.

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

### Camera and fingerprint
- The camera HAL loads again, so the camera and the torch work.
- `/data/goodix` is created with the right SELinux rules and fingerprint recognition is stable.

### Connectivity
- Mobile data works without Wi-Fi, as the IWLAN poll no longer stalls at `POWER_OFF`.

### Keyboard
- Layout overlays no longer replace the built-in Alt/Sym character map.
- German QWERTZ mapping corrected.

### Hardware keys
- Ctrl and Tab remaps now also apply to the Convenience key.
- Home launcher is no longer offered for the Sym, Function or Convenience key.

### Lock screen
- PIN entry no longer queries Settings and `KeyCharacterMap` on every key press.
- Hidden PIN text no longer runs two animators per keystroke.
- Biometric success and error haptics use full-strength constants instead of MSDL.

### Settings and backlight
- Lift to check phone, one-handed mode and Circle to Search are no longer exposed.
- Choosing a custom app in System > Buttons no longer crashes Settings; the per-trigger app settings are now registered with the settings provider.
- The double-press power gesture no longer opens the stock app list or shows a separate App entry; it uses the same icon picker as the other button pickers.
- Navigation key and keyboard backlight stay static when adaptive brightness is off.
- `mq-deadline` with 128 KB read-ahead after boot reduces Settings scrolling jank.

### Security and certification
- SELinux stays enforcing with rules for diagnostics, camera, LED, fingerprint and storage.
- The device passes Play certification with the new CTS overlay.
