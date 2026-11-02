#!/system/bin/sh
#
# collect-diagnostics-service - init service behind Settings > Device
# diagnostics > Collect logs.
#
# The settings app creates its cache/diagnostics folder and sets
# sys.diagnostics.collect=1. This collects a redacted bundle into that folder,
# gives it to the app's user so the app can copy it to Download, and reports
# progress through sys.diagnostics.status: running, then done or failed.

OUT=/data/user/0/com.blackberry.settings/cache/diagnostics

setprop sys.diagnostics.status running
if [ ! -d "$OUT" ]; then
    setprop sys.diagnostics.status failed
    exit 1
fi
owner=$(stat -c %u:%g "$OUT")
rm -rf "$OUT"/*

if /system_ext/bin/collect-diagnostics -L -o "$OUT" >"$OUT/collect.log" 2>&1; then
    status=done
else
    status=failed
fi

# Keep only the archive and the run log; the unpacked copy isn't needed.
for d in "$OUT"/*/; do
    [ -d "$d" ] && rm -rf "$d"
done
chown -R "$owner" "$OUT"
setprop sys.diagnostics.status "$status"
