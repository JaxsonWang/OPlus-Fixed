#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

sh "$MODDIR/gkd-start.sh" >/dev/null 2>&1 &
