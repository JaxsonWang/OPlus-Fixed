#!/bin/sh

MODDIR=${0%/*}

chmod 755 "$MODDIR/clear-fixed.sh"
chmod 755 "$MODDIR/soter-fixed.sh"

. "$MODDIR/clear-fixed.sh"
. "$MODDIR/soter-fixed.sh"

# umont /debug_ramdisk