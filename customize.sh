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

AAPATH1=/system/product/app
AAPATH2=/system/product/priv-app
AAPATH3=/system/product/etc/permissions
AAPATH4=/system/product/overlay
AAPATH5=/system/bin

mkdir -p $MODPATH$AAPATH1
mkdir -p $MODPATH$AAPATH2
mkdir -p $MODPATH$AAPATH3
mkdir -p $MODPATH$AAPATH4
mkdir -p $MODPATH$AAPATH5

mv -f $MODPATH/AA/GoogleTTS $MODPATH$AAPATH1
mv -f $MODPATH/AA/Maps $MODPATH$AAPATH1
mv -f $MODPATH/AA/AndroidAutoStubPrebuilt $MODPATH$AAPATH2
mv -f $MODPATH/AA/Velvet $MODPATH$AAPATH2
mv -f $MODPATH/AA/com.google.android.projection.gearhead.xml $MODPATH$AAPATH3
mv -f $MODPATH/AA/AndroidAutoOverlay $MODPATH$AAPATH4
mv -f $MODPATH/AA/avbctl $MODPATH$AAPATH5

rm -rf $MODPATH/AA

chcon -r u:object_r:system_file:s0 "$MODPATH/system"
set_perm_recursive $MODPATH  0  0  0755  0644
set_perm_recursive  $MODPATH/system/bin  0  2000  0755 0755 u:object_r:same_process_hal_file:s0
