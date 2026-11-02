# CalyxOS for BlackBerry KEY2 (athena)

Unofficial CalyxOS 8.0.4.50 (Android 17) build for the BlackBerry KEY2 (BBF100), running on the Linux 4.19 kernel.

This is a community port. It is not affiliated with, or supported by, the Calyx Institute or BlackBerry.

## Status

The device boots and is in daily use. Confirmed working: calls, mobile data, VoLTE, Wi-Fi calling, Wi-Fi, Bluetooth, the fingerprint sensor, the physical keyboard (including the keyboard touchpad and lockscreen PIN entry), haptics and microSD storage.

SELinux runs in enforcing mode.

The CalyxOS source is used unmodified. The few KEY2 fixes that need changes to it are kept as patch files in [patches/](patches/) and applied before building.

Known limitations:

- Android Auto does not work for now. Installing it from the Play Store is not enough: it must be built into the system image to get the permissions it needs for wireless connections, calls and the Connection preferences entry. CalyxOS builds it in from a proprietary repository that is not public, so this build doesn't include it yet.

See [changelog.md](changelog.md) for the list of fixes and features.

## Device specifications

| | |
|---|---|
| SoC | Qualcomm Snapdragon 660 (SDM660) |
| Memory | 6 GB RAM |
| Display | 4.5" 1620 × 1080 IPS LCD |
| Keyboard | Physical QWERTY with capacitive touchpad |
| Kernel | Linux 4.19 (4.19.325-cip136) |
| Partition layout | Non-A/B |

## Building

Initialise a CalyxOS 8 source tree, then add the device repositories with a local manifest, for example `.repo/local_manifests/athena.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <remote name="kurdworld" fetch="https://github.com/kurdworld/" />

    <project name="android_device_blackberry_athena" path="device/blackberry/athena" remote="kurdworld" revision="calyxos-8" />
    <project name="android_device_blackberry_sdm660-common" path="device/blackberry/sdm660-common" remote="kurdworld" revision="calyxos-8" />
    <project name="android_kernel_blackberry_sdm660" path="kernel/blackberry/sdm660" remote="kurdworld" revision="calyxos-8" />
    <project name="android_vendor_blackberry_athena" path="vendor/blackberry/athena" remote="kurdworld" revision="calyxos-8" />
    <project name="android_vendor_blackberry_sdm660-common" path="vendor/blackberry/sdm660-common" remote="kurdworld" revision="calyxos-8" />

    <remote name="github" fetch="https://github.com/" />
    <project name="LineageOS/android_hardware_qcom_display" path="hardware/qcom-caf/sdm660" remote="github" revision="lineage-24.0-caf-sdm660" />
    <project name="LineageOS/android_hardware_qcom_audio" path="hardware/qcom-caf/sdm660/audio" remote="github" revision="lineage-24.0-caf-sdm660" />
    <project name="LineageOS/android_hardware_qcom_media" path="hardware/qcom-caf/sdm660/media" remote="github" revision="lineage-24.0-caf-sdm660" />
</manifest>
```

Then sync and build:

```bash
repo sync
device/blackberry/athena/patches/apply.sh
source build/envsetup.sh
breakfast athena
m
```

`apply.sh` applies the KEY2 patches to the CalyxOS source; see [patches/README.md](patches/README.md).

## Installing

The KEY2 uses a non-A/B layout. With an unlocked bootloader, from fastboot:

```bash
fastboot flash boot out/target/product/athena/boot.img
fastboot flash system out/target/product/athena/system.img
fastboot flash vendor out/target/product/athena/vendor.img
fastboot flash recovery out/target/product/athena/recovery.img
fastboot reboot
```

A data wipe is required when moving from another ROM. Flashing this build's recovery is needed once, so that later updates can install.


## Reporting problems

Open **Settings > System > BlackBerry settings**, then tap **Collect logs** under **Troubleshooting**. After a few minutes a single compressed file is saved to the Download folder. Personal data such as phone numbers, e-mail, MAC and IP addresses, card numbers, Wi-Fi names and locations is removed before it is saved. Attach that file to your report.

From a computer, the same report can be collected over adb with [tools/collect-diagnostics.sh](tools/collect-diagnostics.sh); run it with `-h` for the options.

## Credits

This port builds directly on the work of:

- **[Lineage-BBKey2](https://github.com/Lineage-BBKey2)**: LineageOS device, vendor and 4.19 kernel trees for the KEY2 and KEY2 LE, including the keyboard, audio, camera, fingerprint, haptics, Wi-Fi calling and graphics fixes reused here.
- **[tim-ecoder](https://github.com/tim-ecoder)** and **[zzach](https://github.com/Lineage-BBKey2)**: the port of the athena device tree and kernel to Linux 4.19.
- **[Igor Belwon](https://github.com/BotchedRPR)**: device tree work in the Lineage-BBKey2 trees.
- **[FumoEnterprises](https://github.com/FumoEnterprises)**: the original LineageOS bring-up for the KEY2, which the trees above are based on.
- **[CalyxOS](https://calyxos.org/)**: the operating system.
- **[LineageOS](https://lineageos.org/)**: the Qualcomm hardware support used by this build.

## License

Source files are licensed under the Apache License, Version 2.0, unless stated otherwise in the file. The kernel is licensed under the GNU General Public License, version 2. Proprietary vendor files remain the property of their respective owners.
