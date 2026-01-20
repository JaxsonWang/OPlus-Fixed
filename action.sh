#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

. "$MODDIR/key-box.sh"

provision_keybox

chmod 755 "$MODDIR/clear-fixed.sh"
. "$MODDIR/clear-fixed.sh"
