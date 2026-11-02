#!/bin/bash
#
# Applies the KEY2 patches to the CalyxOS source tree, or removes them.
#
#   device/blackberry/athena/patches/apply.sh           apply every patch
#   device/blackberry/athena/patches/apply.sh --check   only report the state of each patch
#   device/blackberry/athena/patches/apply.sh --revert  remove every patch again
#
# Each patch lives at patches/<project path>/<name>.patch and is applied inside
# <project path>. Running it twice is safe: applied patches are skipped.

set -u

PATCHES="$(cd "$(dirname "$0")" && pwd)"
TOP="$(cd "$PATCHES/../../../.." && pwd)"
mode="${1:-apply}"

case "$mode" in
    apply|--check|--revert) ;;
    *) echo "usage: $0 [--check|--revert]" >&2; exit 2 ;;
esac

failed=0
while IFS= read -r patch; do
    rel="${patch#"$PATCHES"/}"
    project="$(dirname "$rel")"
    dir="$TOP/$project"

    if [ ! -d "$dir" ]; then
        echo "MISSING  $project (not in this checkout)"
        failed=1
        continue
    fi

    if git -C "$dir" apply --check -R "$patch" 2>/dev/null; then
        state=applied
    elif git -C "$dir" apply --check "$patch" 2>/dev/null; then
        state=clean
    else
        state=conflict
    fi

    case "$mode:$state" in
        --check:*)
            echo "${state^^}  $rel" ;;
        apply:applied|--revert:clean)
            echo "skip     $rel" ;;
        apply:clean)
            git -C "$dir" apply "$patch" && echo "applied  $rel" || { echo "FAILED   $rel"; failed=1; } ;;
        --revert:applied)
            git -C "$dir" apply -R "$patch" && echo "reverted $rel" || { echo "FAILED   $rel"; failed=1; } ;;
        *:conflict)
            echo "CONFLICT $rel: $project has changed, update this patch"
            failed=1 ;;
    esac
done < <(find "$PATCHES" -name '*.patch' | sort)

exit $failed
