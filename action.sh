#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

chmod 755 "$MODDIR/key-box.sh"
chmod 755 "$MODDIR/soter-fixed.sh"
chmod 755 "$MODDIR/clear-fixed.sh"
chmod 755 "$MODDIR/prop.sh"

. "$MODDIR/key-box.sh"

provision_keybox

sh "$MODDIR/clear-fixed.sh"
sh "$MODDIR/prop.sh"
sh "$MODDIR/soter-fixed.sh"

echo "执行结束"
echo "(一秒后自动退出)"
sleep 1
echo "运行结束"
exit
