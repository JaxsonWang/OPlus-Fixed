#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

if [ ! -e "$MODDIR/health-background.disabled" ]; then
    /system/bin/sh "$MODDIR/health-background-fix.sh" --boot &
fi

if [ ! -e "$MODDIR/gkd.disabled" ]; then
    /system/bin/sh "$MODDIR/gkd-start.sh" --boot >/dev/null 2>&1 &
fi
