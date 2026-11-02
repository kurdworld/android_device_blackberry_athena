# Changelog: CalyxOS for BlackBerry KEY2 (athena)

## New in this port
- **Kernel**
    - **Kernel security updates:** Linux 4.19.325-cip128 updated to 4.19.325-cip136, adding about 1,970 upstream fixes.

- **Security**
    - **SELinux enforcing:** the phone now runs with SELinux enforcing instead of permissive. Storage partitions, graphics memory and the graphics library are labelled correctly, the battery, charger, notification LED, camera, CPU/GPU frequency and modem nodes use their kernel 4.19 paths, and the power, thermal, USB, sensor, camera, media, IMS, GPS, time and Wi-Fi MAC services, and the wakeup statistics, have the access they need. No system service is blocked at boot.
    - **Boot logger removed:** a leftover debug logger that ran shell commands at every boot is gone.
    - **Release keys:** builds are signed with private release keys instead of the public test keys, including every system module (APEX), so only this port's own builds can be installed as updates.

- **Performance and boot**
    - **Faster boot:** first-stage init dropped from 20 s to 0.3 s after a metadata partition path fix.
    - **Boot navbar:** the virtual navigation bar no longer flashes during boot.
    - **Memory:** 2 GB lz4 ZRAM, tuned swappiness and page-cluster.
    - **Smoother UI:** system apps now ship precompiled in the system image.
    - **Smoother video in apps:** videos in apps like X no longer freeze for about 2 s when they move on screen (scrolling, opening full screen, next video); the hardware video decoder now switches surfaces instead of failing and restarting.
    - **Temperature reporting:** Android now gets real CPU, GPU, skin and battery temperatures from a Qualcomm thermal service (the old one reported none), so apps and the power manager can react to heat.

- **Audio**
    - **Quieter low ring and notification volume:** the bottom of the ring and notification sliders is now genuinely quiet on the speaker (lowest step about -57 dB instead of -28 dB), rising smoothly to the same maximum loudness as before.

- **Buttons**
    - **Back, Home and Switch buttons:** vibrate when pressed.
    - **Home, Back and App switch buttons:** set what each button does on long press (and Home on double tap, App switch on short press) and answer calls with Home, in System > Buttons.

- **Camera and fingerprint**
    - **Fingerprint and camera libraries:** added the missing libstdc++_vendor library they depend on.

- **Settings and apps**
    - **Over-the-air updates:** new builds are downloaded in the background from the kurdworld/calyxos_updates GitHub releases; tap Reboot in the notification and recovery installs them. The update service is now enabled on these unofficial builds, and update packages are built for the KEY2's fixed partitions.
    - **Version:** Settings > About phone shows the port's own version, BB-CalyxOS-1.0-Unofficial, which goes up with each release.
    - **Collect logs:** new option in Settings > System > BlackBerry settings > Troubleshooting saves a diagnostic report as one file in the Download folder, with personal data removed, to attach when reporting a problem.
    - **Settings:** no more freezing when switching pages (telephony no longer waits 2 s for a radio HAL the KEY2 doesn't have).
    - **Brave and Chromium browsers:** fixed sandboxed tabs crashing on the 4.19 kernel (zygote_next capability check).
    - **Cleaner build:** removed the unused BlackBerry Camera, K12KB, BlackBerry Keyboard (VN) and Lokker app entries, and the unused Qualcomm IWlanService (Wi-Fi calling goes through the modem).

- **Source**
    - **Unmodified CalyxOS:** the CalyxOS source folders are no longer edited. The KEY2 changes they need are kept as patch files in patches/, applied with patches/apply.sh before building.

## From other developers

- **Keyboard and touchpad**
    - **Speed key:** now acts as Ctrl. *Credit: [zzach]*
    - **Keyboard symbols:** Alt and Sym layers on the physical keyboard work again; keyboard layout overlays no longer replace the built-in key map. *Credit: [tim-ecoder]*
    - **Keyboard switching:** the IME switcher shortcut works again; Alt+Enter by default, or Shift+Space, Ctrl or SYM from BlackBerry settings. *Credit: [tim-ecoder], [zzach]*
    - **Keyboard PIN entry:** type the lockscreen PIN on the keyboard without holding Alt or swiping, even with the screen off. *Credit: [zzach]*
    - **Keyboard touchpad:** touching the keyboard no longer registers as taps on the screen; it is now a proper touchpad. *Credit: [tim-ecoder]*
    - **Keyboard scrolling:** swipe on the keyboard to scroll lists and pages, with momentum. *Credit: [tim-ecoder], [zzach]*
    - **Touchpad and scrolling toggles:** new "Keyboard touchpad" and "Keyboard scrolling" switches in BlackBerry settings, and matching Quick Settings tiles. *Credit: [tim-ecoder], [zzach]*

- **Buttons, haptics and lights**
    - **Vibrator:** the vibration motor is no longer also claimed by the input system, so only the vibrator service drives it. *Credit: [zzach]*
    - **Buttons:** added Search/Assistant key options. *Credit: [LineageOS], [Igor Belwon]*
    - **Haptics:** fingerprint and click feedback are back to full strength, matching the old kernel 4.4 builds. *Credit: [zzach]*
    - **Fingerprint unlock vibration:** now clearly felt; the lockscreen uses the KEY2's own full-strength biometric vibration instead of a short generic pattern meant for newer vibration motors. *Credit: [zzach]*
    - **Keyboard and button backlight:** the brightness sliders now change the real lights, and the backlight timeout setting works. *Credit: [tim-ecoder], [zzach]*
    - **Notification light:** the colour picker preview now lights the LED with the screen on. *Credit: [tim-ecoder]*

- **Camera and fingerprint**
    - **Flashlight and camera:** restored the display service HAL the camera blob needs; the torch is now white instead of yellow (kernel follows the HAL's dual-tone LED currents). *Credit: [AOSP], [zzach]*
    - **Fingerprint:** faster unlock; the sensor keeps the phone awake briefly after a touch so the reading isn't delayed. *Credit: [zzach]*

- **Connectivity and storage**
    - **Wi-Fi calling:** now works; the Qualcomm network service (CNE) can start, so the modem is told when Wi-Fi is available and registers calls over it. The radio library also no longer drops a valid Wi-Fi network from the network list. *Credit: [zzach], [tim-ecoder]*
    - **Mobile data:** the carrier APN list is installed again, so data and internet work (CalyxOS leaves it out by default). *Credit: [AOSP]*
    - **microSD card and USB storage:** detected again; the storage entries in fstab now use the kernel 4.19 device paths. *Credit: [tim-ecoder]*
    - **NFC compatibility:** restored the BlackBerry PN553 NFC settings for card polling, presence checks and long transfers. *Credit: [zzach]*
    - **Bluetooth AAC:** Bluetooth headphones that support AAC now use it instead of SBC, for better sound quality. *Credit: [zzach]*

- **Performance**
    - **Smoother scrolling:** updated the Adreno GPU drivers to the SDM660-native r155 set; scrolling in apps like X has about a third fewer janky frames. *Credit: [tim-ecoder]*

- **Audio**
    - **Volume:** 14 call, 14 ring, 14 notification and 30 media volume steps, matching the older KEY2 builds. *Credit: [zzach]*

- **Settings and apps**
    - **BlackBerry settings:** renamed from "BlackBerry keyboard" and added a "Keyboard PIN input" toggle. *Credit: [zzach], [tim-ecoder]*

- **Foundations**
    - **Linux 4.19 kernel for the KEY2:** keyboard, touch keyboard, Goodix fingerprint, notification LED, haptics, camera, Bluetooth, encryption and exFAT support. *Credit: [tim-ecoder]*
    - **Device and vendor trees:** graphics stack, Bluetooth and thermal libraries, VoLTE and Wi-Fi calling, keyboard layout detection, Widevine DRM, GPS, camera shims and display fixes. *Credit: [tim-ecoder], [zzach], [Igor Belwon]*
    - **BlackBerry settings app:** *Credit: [tim-ecoder], [zzach]*

[tim-ecoder]: https://github.com/tim-ecoder
[zzach]: https://github.com/Lineage-BBKey2
[Igor Belwon]: https://github.com/BotchedRPR
[LineageOS]: https://github.com/LineageOS
[AOSP]: https://android.googlesource.com/
