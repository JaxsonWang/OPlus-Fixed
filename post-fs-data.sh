#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR=${0%/*}

if [ -f "$MODDIR/refresh-rate-165.enabled" ]; then
    /system/bin/sh "$MODDIR/refresh-rate-165.sh" --mount > "$MODDIR/refresh-rate-165.log" 2>&1 ||
        echo "+ [165Hz] 挂载失败，请查看 $MODDIR/refresh-rate-165.log" >&2
fi
