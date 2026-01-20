#!/bin/sh
PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"
. "$MODDIR/key-box.sh"

copy_library() {
    cp /vendor/lib64/libminkdescriptor.so "$MODDIR/"
    chmod 644 "$MODDIR/libminkdescriptor.so"
    log "Copied libminkdescriptor.so to module directory"
}

copy_library
provision_keybox

chmod 755 "$MODDIR/clear-fixed.sh"
. "$MODDIR/clear-fixed.sh"
