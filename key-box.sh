#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

chmod 755 "$MODDIR/clear-fixed.sh"
. "$MODDIR/clear-fixed.sh"

LOG="$MODDIR/log.txt"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
}

check_root() {
    log "Checking root access..."
    su -c "echo root access OK" >> "$LOG" 2>&1
}

run_keybox_install() {
    log "Running KmInstallKeybox..."
    chmod 755 "$MODDIR/KmInstallKeybox"
    su -mm -c "LD_LIBRARY_PATH=$MODDIR:/vendor/lib64 $MODDIR/KmInstallKeybox Keybox_file Device_ID true true" >> "$LOG" 2>&1
}

provision_keybox() {
    log "==== Keybox provisioning start ===="
    check_root
    run_keybox_install
    log "==== Keybox provisioning end ===="
}
