#!/bin/sh
#
# collect-diagnostics.sh - collect a diagnostics bundle from an Android device.
#
# Gathers device and build info, logs (current and previous boot, kernel),
# crash and ANR reports, every dumpsys service, HALs, packages, settings,
# network, input, power and SELinux state. Writes SUMMARY.txt pointing at
# likely problems and packs everything into one .tar.gz to share.
#
# Runs from a computer over adb, or on the device itself with -L (this is
# what BlackBerry settings > Collect logs uses). Works with any
# Android device; root (adb root, su, or running as root on the device) is
# used when available for kernel logs, tombstones and other root-only data.
#
# Usage: collect-diagnostics.sh [options]
#   -s SERIAL    device serial, when more than one device is connected
#   -o DIR       where to write the bundle (default: current directory)
#   -L           run on the device itself instead of over adb
#   -r           reproduce mode: record live logs while you reproduce the
#                problem, then press Enter
#   -t SECONDS   like -r, but stop recording after SECONDS
#   -q           quick: dump a core set of services instead of all of them
#   -b           also run "adb bugreport" (slow, very large; not with -L)
#   -p           also take a screenshot
#   -n           don't try to get root
#   -R           don't redact personal data (phone numbers, IMEI/ICCID-like
#                numbers, card numbers, e-mail, MAC and IP addresses, Wi-Fi
#                names, locations, serial number)
#   -h           show this help

set -u
SCRIPT_VERSION=1.1

SERIAL=""
OUTBASE="."
LOCAL=0
REPRO=0
REPRO_SECS=0
QUICK=0
BUGREPORT=0
SCREENSHOT=0
TRY_ROOT=1
REDACT=1
OPTIONS="$*"

# Services dumped in quick mode (when present on the device).
QUICK_SERVICES="activity alarm audio battery batterystats biometric bluetooth_manager
carrier_config companiondevice connectivity cpuinfo deviceidle display face fingerprint
gfxinfo input input_method isub jobscheduler location media.audio_flinger
media.audio_policy media.camera meminfo mount netpolicy notification package phone
power sensorservice SurfaceFlinger telecom telephony.registry thermalservice usb
vibrator_manager wifi wifip2p window"

usage() { sed -n '2,/^$/s/^# \{0,1\}//p' "$0"; }
log() { printf '%s\n' "$*" >&2; }
die() { log "error: $*"; exit 1; }

while getopts "s:o:Lrt:qbpnRh" opt; do
    case $opt in
        s) SERIAL=$OPTARG ;;
        o) OUTBASE=$OPTARG ;;
        L) LOCAL=1 ;;
        r) REPRO=1 ;;
        t) REPRO=1; REPRO_SECS=$OPTARG ;;
        q) QUICK=1 ;;
        b) BUGREPORT=1 ;;
        p) SCREENSHOT=1 ;;
        n) TRY_ROOT=0 ;;
        R) REDACT=0 ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
case $REPRO_SECS in *[!0-9]*|'') die "-t needs a number of seconds" ;; esac

if command -v timeout >/dev/null 2>&1; then TIMEOUT=timeout
elif command -v gtimeout >/dev/null 2>&1; then TIMEOUT=gtimeout
else TIMEOUT=""
fi

# with_timeout SECONDS CMD...: run CMD, killing it after SECONDS if possible.
with_timeout() {
    secs=$1
    shift
    if [ -n "$TIMEOUT" ]; then "$TIMEOUT" "$secs" "$@"; else "$@"; fi
}

SERIAL_ARGS=""
[ -n "$SERIAL" ] && SERIAL_ARGS="-s $SERIAL"

# devsh SECONDS CMD: run shell command CMD on the device.
devsh() {
    if [ "$LOCAL" = 1 ]; then
        with_timeout "$1" sh -c "$2" </dev/null
    else
        with_timeout "$1" adb $SERIAL_ARGS shell "$2" </dev/null
    fi
}

# dev CMD: run CMD on the device and print its output.
dev() { devsh 60 "$1" 2>/dev/null | tr -d '\r'; }

# Root: "local" (running as root on the device), "adbd" (adb root), "su", or "none".
ROOT=none
if [ "$LOCAL" = 1 ]; then
    command -v getprop >/dev/null 2>&1 || die "-L only works on an Android device"
    [ "$TRY_ROOT" = 1 ] && [ "$(id -u)" = 0 ] && ROOT=local
    BUGREPORT=0
else
    command -v adb >/dev/null 2>&1 || die "adb not found; install Android platform-tools and add them to PATH"
    state=$(adb $SERIAL_ARGS get-state 2>&1)
    [ "$state" = device ] || die "no device ready ($state). Connect one device with USB debugging on, or pick one with -s."
    if [ "$TRY_ROOT" = 1 ]; then
        if [ "$(dev 'id -u')" = 0 ]; then
            ROOT=adbd
        elif [ "$(dev 'getprop ro.debuggable')" = 1 ]; then
            log "Restarting adbd as root..."
            adb $SERIAL_ARGS root >/dev/null 2>&1
            sleep 2
            adb $SERIAL_ARGS wait-for-device
            [ "$(dev 'id -u')" = 0 ] && ROOT=adbd
        fi
        if [ "$ROOT" = none ] && [ -n "$(dev 'command -v su')" ]; then
            log "Asking for root through su; allow it if the phone shows a prompt..."
            [ "$(devsh 30 'su -c id -u' 2>/dev/null | tr -d '\r')" = 0 ] && ROOT=su
        fi
    fi
fi

MODEL=$(dev 'getprop ro.product.model' | tr -c 'A-Za-z0-9._\n-' '_')
NAME="diag-${MODEL:-device}-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTBASE" || die "can't create $OUTBASE"
OUT="$OUTBASE/$NAME"
mkdir -p "$OUT" || die "can't create $OUT"
COLLECT_LOG="$OUT/collection-log.txt"
{
    echo "collect-diagnostics.sh $SCRIPT_VERSION"
    echo "host: $(uname -a)"
    if [ "$LOCAL" = 1 ]; then echo "mode: on device"; else echo "adb: $(adb version 2>/dev/null | head -n 1)"; fi
    echo "options: $OPTIONS"
    echo "root: $ROOT"
    echo "started: $(date)"
    echo
    echo "exit-code  seconds  file"
} >"$COLLECT_LOG"

BG_PIDS=""
cleanup() {
    [ -n "$BG_PIDS" ] && kill $BG_PIDS 2>/dev/null
    log ""
    log "Interrupted; partial results are in $OUT"
    exit 130
}
trap cleanup INT TERM

# remote CMD ASROOT: CMD wrapped in su when root comes from su.
remote() {
    if [ "$2" = 1 ] && [ "$ROOT" = su ]; then
        printf "su -c '%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
    else
        printf '%s' "$1"
    fi
}

# run FILE CMD [ROOT] [TIMEOUT]: save the output of device command CMD to FILE.
# ROOT: 0 = plain shell, 1 = needs root (skipped without it), 2 = root if available.
run() {
    file=$1
    cmd=$2
    asroot=${3:-0}
    secs=${4:-120}
    if [ "$asroot" = 2 ]; then
        if [ "$ROOT" = none ]; then asroot=0; else asroot=1; fi
    fi
    if [ "$asroot" = 1 ] && [ "$ROOT" = none ]; then
        echo "skipped    -        $file (needs root)" >>"$COLLECT_LOG"
        return 0
    fi
    mkdir -p "$OUT/$(dirname "$file")"
    start=$(date +%s)
    printf '$ %s\n\n' "$cmd" >"$OUT/$file"
    devsh "$secs" "$(remote "$cmd" "$asroot")" >>"$OUT/$file" 2>&1
    rc=$?
    [ "$rc" = 124 ] && echo "[timed out after ${secs}s]" >>"$OUT/$file"
    printf '%-10s %-8s %s\n' "$rc" "$(( $(date +%s) - start ))" "$file" >>"$COLLECT_LOG"
    return 0
}

# grab FILE PATH...: archive root-only device paths into FILE (a tar file).
grab() {
    file=$1
    shift
    if [ "$ROOT" = none ]; then
        echo "skipped    -        $file (needs root)" >>"$COLLECT_LOG"
        return 0
    fi
    mkdir -p "$OUT/$(dirname "$file")"
    if [ "$LOCAL" = 1 ]; then
        tar -cf "$OUT/$file" "$@" 2>/dev/null
    else
        with_timeout 300 adb $SERIAL_ARGS exec-out "$(remote "tar -cf - $* 2>/dev/null" 1)" </dev/null >"$OUT/$file"
    fi
    if [ -s "$OUT/$file" ]; then
        echo "ok         -        $file" >>"$COLLECT_LOG"
    else
        rm -f "$OUT/$file"
        echo "empty      -        $file ($*)" >>"$COLLECT_LOG"
    fi
}

# --- Reproduce mode: record live logs while the user reproduces the problem ---
if [ "$REPRO" = 1 ]; then
    mkdir -p "$OUT/reproduce"
    repro_start=$(dev 'date')
    if [ "$LOCAL" = 1 ]; then
        logcat -b all -v threadtime -T 1 </dev/null >"$OUT/reproduce/logcat.txt" 2>&1 &
    else
        adb $SERIAL_ARGS logcat -b all -v threadtime -T 1 </dev/null >"$OUT/reproduce/logcat.txt" 2>&1 &
    fi
    BG_PIDS=$!
    if [ "$ROOT" != none ]; then
        devsh 86400 "$(remote 'dmesg -w' 1)" >"$OUT/reproduce/dmesg.txt" 2>&1 &
        BG_PIDS="$BG_PIDS $!"
    fi
    if [ "$REPRO_SECS" -gt 0 ]; then
        log "Recording for $REPRO_SECS seconds. Reproduce the problem now."
        sleep "$REPRO_SECS"
    else
        log "Recording. Reproduce the problem now, then press Enter here."
        read -r _
    fi
    kill $BG_PIDS 2>/dev/null
    wait 2>/dev/null
    BG_PIDS=""
    printf 'Recording started (device time): %s\nRecording stopped (device time): %s\n' \
        "$repro_start" "$(dev 'date')" >"$OUT/reproduce/README.txt"
fi

log "Collecting into $OUT (root: $ROOT)"

# --- Device, build and hardware state ---
log "  device state"
run device/getprop.txt 'getprop'
run device/kernel.txt 'uname -a; echo; cat /proc/version; echo; cat /proc/cmdline' 2
run device/kernel-config.txt 'zcat /proc/config.gz' 2
run device/uptime.txt 'date; uptime; cat /proc/loadavg'
run device/identity-selinux.txt 'id; getenforce'
run device/meminfo.txt 'cat /proc/meminfo; echo; cat /proc/vmstat; echo; cat /proc/swaps'
run device/cpuinfo.txt 'cat /proc/cpuinfo'
run device/cpufreq.txt 'for c in /sys/devices/system/cpu/cpu[0-9]*; do echo "== $c online=$(cat $c/online 2>/dev/null)"; for f in scaling_governor scaling_cur_freq scaling_min_freq scaling_max_freq cpuinfo_max_freq; do echo "$f=$(cat $c/cpufreq/$f 2>/dev/null)"; done; done'
run device/thermal.txt 'for z in /sys/class/thermal/thermal_zone*; do echo "$(cat $z/type 2>/dev/null) $(cat $z/temp 2>/dev/null)"; done' 2
run device/power-supply.txt 'for p in /sys/class/power_supply/*; do echo "== $p"; cat $p/uevent 2>/dev/null; done' 2
run device/storage.txt 'df -h; echo; mount; echo; cat /proc/partitions' 2
run device/block-by-name.txt 'ls -l /dev/block/by-name /dev/block/platform/*/by-name /dev/block/platform/*/*/by-name 2>/dev/null' 1
run device/processes.txt 'ps -A -Z; echo; ps -A -l'
run device/top.txt 'top -b -n 1 -m 60'
run device/interrupts.txt 'cat /proc/interrupts'
run device/wakeup-sources.txt 'cat /sys/kernel/debug/wakeup_sources 2>/dev/null || cat /d/wakeup_sources' 1
[ "$QUICK" = 0 ] && run device/threads.txt 'ps -A -T -l' 0 180

# --- Logs ---
log "  logs"
run logs/logcat.txt 'logcat -b all -d -v threadtime' 0 300
run logs/logcat-crash.txt 'logcat -b crash -d -v threadtime'
run logs/logcat-previous-boot.txt 'logcat -L -b all -d -v threadtime' 0 300
run logs/dmesg.txt 'dmesg' 2
grab logs/pstore.tar /sys/fs/pstore /proc/last_kmsg

# --- Crashes and hangs ---
log "  crash and ANR reports"
run crashes/dropbox.txt 'dumpsys dropbox --print' 0 300
grab crashes/tombstones.tar /data/tombstones
grab crashes/anr.tar /data/anr

# --- System services ---
SERVICES=$(dev 'dumpsys -l' | awk 'NR > 1 { print $1 }' | grep -vx dropbox)
if [ "$QUICK" = 1 ]; then
    all=" $(echo $SERVICES) "
    SERVICES=""
    for s in $QUICK_SERVICES; do
        case $all in *" $s "*) SERVICES="$SERVICES $s" ;; esac
    done
fi
total=0
for s in $SERVICES; do total=$((total + 1)); done
log "  $total system services"
printf '%s\n' $SERVICES >"$OUT/services-list.txt"
i=0
for s in $SERVICES; do
    i=$((i + 1))
    [ -t 2 ] && printf '\r    %d/%d %-50.50s' "$i" "$total" "$s" >&2
    run "services/$(printf '%s' "$s" | tr '/' '_').txt" "dumpsys -t 30 '$s'" 0 60
done
[ -t 2 ] && printf '\r%70s\r' '' >&2

# --- HALs ---
log "  HALs"
run hal/lshal.txt 'lshal' 2 90
run hal/service-list.txt 'service list'
run hal/vintf-manifests.txt 'for f in /vendor/etc/vintf/manifest.xml /vendor/etc/vintf/manifest/*.xml /odm/etc/vintf/manifest*.xml /system/etc/vintf/manifest.xml /system/etc/vintf/manifest/*.xml; do [ -f "$f" ] && { echo "===== $f"; cat "$f"; }; done' 2

# --- Packages, settings and flags ---
log "  packages and settings"
run packages/packages.txt 'pm list packages -f -U --show-versioncode -u'
run packages/disabled.txt 'pm list packages -d'
run packages/features.txt 'pm list features'
run packages/libraries.txt 'pm list libraries'
run packages/overlays.txt 'cmd overlay list'
run settings/global.txt 'settings list global'
run settings/secure.txt 'settings list secure'
run settings/system.txt 'settings list system'
run settings/device-config.txt 'cmd device_config list'
run settings/aconfig-flags.txt 'aflags list'

# --- Network ---
log "  network"
run network/ip.txt 'ip addr; echo; ip -4 rule; echo; ip -6 rule; echo; ip -4 route show table all; echo; ip -6 route show table all' 2
run network/interfaces.txt 'cat /proc/net/dev; echo; cat /proc/net/wireless 2>/dev/null'
run network/firewall.txt 'iptables-save; echo; ip6tables-save' 1
run network/reachability.txt 'ping -c 2 -W 3 8.8.8.8; echo; ping -c 2 -W 3 dns.google; echo; ping6 -c 2 -W 3 2001:4860:4860::8888' 0 40

# --- Input ---
log "  input devices"
run input/getevent.txt 'getevent -lp' 0 30
run input/devices.txt 'cat /proc/bus/input/devices'

# --- Optional extras ---
if [ "$SCREENSHOT" = 1 ]; then
    log "  screenshot"
    if [ "$LOCAL" = 1 ]; then
        screencap -p "$OUT/screenshot.png" 2>/dev/null
    else
        adb $SERIAL_ARGS exec-out screencap -p </dev/null >"$OUT/screenshot.png" 2>/dev/null
    fi
fi
if [ "$BUGREPORT" = 1 ]; then
    log "  bugreport (this takes a few minutes)"
    adb $SERIAL_ARGS bugreport "$OUT/bugreport.zip" </dev/null >>"$COLLECT_LOG" 2>&1
fi

echo "finished: $(date)" >>"$COLLECT_LOG"

# --- Redact personal data from the text files (best effort) ---
# Number rules run twice so that matches next to each other are all caught.
if [ "$REDACT" = 1 ]; then
    log "  redacting personal data"
    SERIALNO=$(dev 'getprop ro.serialno' | tr -cd 'A-Za-z0-9')
    find "$OUT" -type f -name '*.txt' | while IFS= read -r f; do
        sed -E -i.bak \
            -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}/<email>/g' \
            -e 's/([0-9A-Fa-fXx]{2}[:-]){5}[0-9A-Fa-fXx]{2}/<mac>/g' \
            -e 's/(^|[^0-9A-Za-z.:])[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{0,4}){4,7}/\1<ip>/g' \
            -e 's/(^|[^0-9A-Za-z.:])[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4})*::([0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4})*)?/\1<ip>/g' \
            -e 's/(^|[^0-9.])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)/\1<ip>\3/g' \
            -e 's/(^|[^0-9.])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)/\1<ip>\3/g' \
            -e 's/(^|[^0-9])(4[0-9]{3}|5[1-5][0-9]{2}|2[2-7][0-9]{2}|6011|65[0-9]{2})([ -]?[0-9]{4}){3}([^0-9]|$)/\1<card>\4/g' \
            -e 's/(^|[^0-9])3[47][0-9]{2}[ -]?[0-9]{6}[ -]?[0-9]{5}([^0-9]|$)/\1<card>\2/g' \
            -e 's/(^|[^0-9])89[0-9]{16,18}([^0-9]|$)/\1<iccid>\2/g' \
            -e 's/(^|[^0-9])[0-9]{15}([^0-9]|$)/\1<id>\2/g' \
            -e 's/(^|[^0-9])[0-9]{15}([^0-9]|$)/\1<id>\2/g' \
            -e 's/\+[0-9][0-9 -]{6,16}[0-9]/<phone>/g' \
            -e 's/(tel|sip|sips):[^ ,;<>"]+/\1:<phone>/g' \
            -e 's/(^|[^0-9.])0[0-9]{9,10}([^0-9]|$)/\1<phone>\2/g' \
            -e 's/(^|[^0-9.])0[0-9]{3,4} [0-9]{3} ?[0-9]{3,4}([^0-9]|$)/\1<phone>\2/g' \
            -e 's/([Ss][Ss][Ii][Dd][=: ]+)"[^"]*"/\1"<ssid>"/g' \
            -e 's/([Ss][Ss][Ii][Dd]=)[^ ,;"]+/\1<ssid>/g' \
            -e 's/(android_id[=: ]+)[0-9A-Fa-f]+/\1<id>/g' \
            -e 's/-?[0-9]{1,3}\.[0-9]{4,}, ?-?[0-9]{1,3}\.[0-9]{4,}/<location>/g' \
            ${SERIALNO:+-e "s/$SERIALNO/<serial>/g"} \
            "$f" && rm -f "$f.bak"
    done
fi

# --- Summary: quick pointers to likely problems ---
log "  writing summary"
LOGS="$OUT/.all-logs"
cat "$OUT"/logs/logcat.txt "$OUT"/logs/logcat-previous-boot.txt "$OUT"/logs/dmesg.txt \
    "$OUT"/reproduce/logcat.txt "$OUT"/reproduce/dmesg.txt 2>/dev/null | sort -u >"$LOGS"

prop() { grep -m 1 "^\[$1\]" "$OUT/device/getprop.txt" 2>/dev/null | sed 's/.*: \[\(.*\)\]/\1/'; }
count() { grep -cE "$1" "$LOGS"; }
ranked() { sed 's/^/      /' | sort | uniq -c | sort -rn | head -n "${1:-10}"; }

{
    echo "Diagnostics summary ($NAME)"
    echo "Collected $(date) with collect-diagnostics.sh $SCRIPT_VERSION, root: $ROOT"
    echo
    echo "Device:        $(prop ro.product.manufacturer) $(prop ro.product.model) ($(prop ro.product.device))"
    echo "Build:         $(prop ro.build.fingerprint)"
    echo "Build date:    $(prop ro.build.date)"
    echo "Patch level:   $(prop ro.build.version.security_patch)"
    echo "Kernel:        $(grep -m 1 'Linux' "$OUT/device/kernel.txt" 2>/dev/null)"
    echo "SELinux:       $(tail -n 1 "$OUT/device/identity-selinux.txt" 2>/dev/null)"
    echo "Uptime:        $(sed -n 4p "$OUT/device/uptime.txt" 2>/dev/null)"
    echo "Boot reason:   $(prop sys.boot.reason) (history: $(prop persist.sys.boot.reason.history | tr '\n' ' '))"
    echo "Battery:       $(grep -E '^ *(level|temperature|status|health):' "$OUT/services/battery.txt" 2>/dev/null | tr -s ' ' | tr '\n' ' ')"
    echo "Data storage:  $(grep -E ' /data$' "$OUT/device/storage.txt" 2>/dev/null | head -n 1)"
    [ -f "$OUT/reproduce/README.txt" ] && { echo; cat "$OUT/reproduce/README.txt"; }
    echo
    echo "Indicators from all collected logs (look here first):"
    echo
    echo "  App crashes (FATAL EXCEPTION): $(count 'FATAL EXCEPTION')"
    grep -o 'Process: [^,]*' "$LOGS" | ranked
    echo "  Native crashes (Fatal signal): $(count 'Fatal signal [0-9]+')"
    grep -E 'Fatal signal [0-9]+' "$LOGS" | sed -E 's/.*Fatal signal ([0-9]+ \([A-Z]+\)).*pid [0-9]+ \(([^)]*)\).*/\2 \1/' | ranked
    echo "  ANRs: $(count 'ANR in ')"
    grep -oE 'ANR in [^ ]+' "$LOGS" | ranked
    echo "  System server crashes/watchdog: $(count 'FATAL EXCEPTION IN SYSTEM PROCESS|WATCHDOG KILLING SYSTEM PROCESS|Watchdog: \*\*\*')"
    echo "  Native services that died (init):"
    grep -oE "Service '[^']+' \(pid [0-9]+\) (received signal [0-9]+|exited with status [1-9][0-9]*|crashed)" "$LOGS" |
        sed -E 's/ \(pid [0-9]+\)//' | ranked 15
    echo "  SELinux denials: $(count 'avc: *denied') (unique below)"
    grep -oE 'avc: *denied *\{[^}]*\}.*scontext=[^ ]+ tcontext=[^ ]+ tclass=[^ ]+' "$LOGS" |
        sed -E 's/\} .*scontext=/} scontext=/' | ranked 20
    echo "  Low-memory kills: $(count 'lowmemorykiller|lmkd.*[Kk]ill')"
    echo "  Kernel errors (panic, oops, BUG, watchdog bite): $(count 'Kernel panic|Internal error: Oops|BUG: |Unable to handle kernel|watchdog bite')"
    echo "  Kernel warnings (WARNING: CPU): $(count 'WARNING: CPU')"
    echo "  Thermal throttling/shutdown messages: $(grep -ciE 'thermal.*(shutdown|throttl)|overheat' "$LOGS")"
    echo
    echo "Bundle contents: device/ logs/ crashes/ services/ hal/ packages/ settings/ network/ input/"
    echo "collection-log.txt lists every item collected, its exit code and what was skipped."
    [ "$REDACT" = 1 ] && echo "Personal data in .txt files was redacted (best effort); .tar/.png/.zip files are not."
} >"$OUT/SUMMARY.txt"
rm -f "$LOGS"

tar -czf "$OUTBASE/$NAME.tar.gz" -C "$OUTBASE" "$NAME" || die "couldn't create the archive"
log ""
log "Done. Bundle: $OUTBASE/$NAME.tar.gz ($(du -h "$OUTBASE/$NAME.tar.gz" | cut -f1))"
log "Start with $OUT/SUMMARY.txt. Review the bundle before sharing it."
echo "$OUTBASE/$NAME.tar.gz"
