#!/bin/sh
PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

chmod 755 "$MODDIR/key-box.sh"
chmod 755 "$MODDIR/soter-fixed.sh"
chmod 755 "$MODDIR/clear-fixed.sh"
chmod 755 "$MODDIR/prop.sh"

. "$MODDIR/key-box.sh"

copy_library() {
    cp /vendor/lib64/libminkdescriptor.so "$MODDIR/"
    chmod 644 "$MODDIR/libminkdescriptor.so"
    log "Copied libminkdescriptor.so to module directory"
}

copy_library
provision_keybox

sh "$MODDIR/clear-fixed.sh"
sh "$MODDIR/prop.sh"
sh "$MODDIR/soter-fixed.sh"