#!/bin/sh
PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH

ui_print "Moduel Version: $(grep versionCode $MODPATH/module.prop | sed 's/versionCode=//g')"
ui_print "Android Version: $(getprop ro.build.version.release)"
ui_print "API Version: $(getprop ro.product.cpu.abi)"
ui_print "Software Version: $(getprop ro.build.display.id.show)"

# Remove applications
REPLACE="
/system/product/app/Browser
/system/product/app/OplusSecurityKeyboard
"

if [ -d /data/adb/modules/tricky_store ]; then
  mkdir -p /data/adb/tricky_store
  mv "$MODPATH/keybox.xml" /data/adb/tricky_store
else
  ui_print "- TrickyStore module not installed!"
fi

chcon -r u:object_r:system_file:s0 "$MODPATH/system"
set_perm_recursive $MODPATH  0  0  0755  0644
set_perm_recursive $MODPATH/system/bin  0  2000  0755 0755 u:object_r:same_process_hal_file:s0
