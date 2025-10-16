#!/bin/sh
PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

# echo $MODDIR > $MODDIR/log.txt

resetprop ro.boot.flash.locked 1
resetprop ro.boot.verifiedbootstate green
resetprop ro.secureboot.lockstate locked
resetprop ro.boot.vbmeta.device_state locked
resetprop ro.debuggable 0
resetprop -n persist.logd.size ""
resetprop -n persist.logd.size.crash ""
resetprop -n persist.logd.size.main ""
resetprop -n persist.log.tag ""
[[ " encrypted " == " $(getprop ro.crypto.state encrypted) " ]] && : || resetprop ro.crypto.state encrypted
SDK_Resolve() {
  settings delete global hidden_api_policy
  settings delete global hidden_api_policy_p_apps
  settings delete global hidden_api_policy_pre_p_apps
  settings delete global hidden_api_blacklist_exemptions
  settings delete global hidden_api_blacklist_exe
}
logcat -c
logcat --clear
dmesg -c
if [ $(settings get global hidden_api_policy) != "null" ]; then
  SDK_Resolve
fi
if [ $(settings get global hidden_api_policy_p_apps) != "null" ]; then
  SDK_Resolve
fi
if [ $(settings get global hidden_api_policy_pre_p_apps) != "null" ]; then
  SDK_Resolve
fi
if [ $(settings get global hidden_api_blacklist_exemptions) != "null" ]; then
  SDK_Resolve
fi
if [ $(settings get global hidden_api_blacklist_exe) != "null" ]; then
  SDK_Resolve
fi
IS_Virtual=0
DetectVirtualMachine() {
  if dmidecode -s system-product-name | grep -q -E "VMware|VirtualBox|KVM|QEMU"; then
    IS_Virtual=1
  fi
  if [[ $(df -h /sdcard /dev | awk 'NR==2 {print $3}' | sed 's/G$//') -le 10 ]]; then
    IS_Virtual=1
  fi
}
check_reset_prop() {
  local NAME=$1
  local EXPECTED=$2
  local VALUE=$(resetprop $NAME)
  [ -z $VALUE ] || [ $VALUE = $EXPECTED ] || resetprop $NAME $EXPECTED
}
contains_reset_prop() {
  local NAME=$1
  local CONTAINS=$2
  local NEWVAL=$3
  [[ "$(resetprop $NAME)" = *"$CONTAINS"* ]] && resetprop $NAME $NEWVAL
}
resetprop -w sys.boot_completed 0
resetprop ro.boot.mode normal
resetprop ro.bootmode normal
check_reset_prop "ro.boot.vbmeta.device_state" "locked"
check_reset_prop "ro.boot.verifiedbootstate" "green"
check_reset_prop "ro.boot.flash.locked" "1"
check_reset_prop "ro.boot.veritymode" "enforcing"
check_reset_prop "ro.boot.warranty_bit" "0"
check_reset_prop "ro.warranty_bit" "0"
check_reset_prop "ro.debuggable" "0"
check_reset_prop "ro.force.debuggable" "0"
check_reset_prop "ro.secure" "1"
check_reset_prop "ro.adb.secure" "1"
check_reset_prop "ro.build.type" "user"
check_reset_prop "ro.build.tags" "release-keys"
check_reset_prop "ro.vendor.boot.warranty_bit" "0"
check_reset_prop "ro.vendor.warranty_bit" "0"
check_reset_prop "vendor.boot.vbmeta.device_state" "locked"
check_reset_prop "vendor.boot.verifiedbootstate" "green"
check_reset_prop "sys.oem_unlock_allowed" "0"
# MIUI 相关
check_reset_prop "ro.secureboot.lockstate" "locked"
# Realme 相关
check_reset_prop "ro.boot.realmebootstate" "green"
check_reset_prop "ro.boot.realme.lockstate" "1"
# 当magisk处于恢复模式时
contains_reset_prop "ro.bootmode" "recovery" "unknown"
contains_reset_prop "ro.boot.bootmode" "recovery" "unknown"
contains_reset_prop "vendor.boot.bootmode" "recovery" "unknown"

# Wait for the system to complete booting
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
resetprop -n init.svc.adbd stopped
contains_reset_prop "ro.build.tags" "test-keys" "release-keys"
contains_reset_prop "ro.build.type" "userdebug" "user"
sleep 5
while true; do
  [[ -d /data/user/0/android ]] && break || sleep 5
done
resetprop -n init.svc.adbd stopped

[[ -d /data/user/0/com.sevtinge.cemiuiler ]] && setprop persist.hyperceiler.log.level "" || :
if [ -d /storage/emulated/0/TWRP ]; then
  rm -rf /storage/emulated/0/TWRP
fi
if [ -d /data/adb/modules/zn_magisk_compat/ ]; then
  rm -rf /data/adb/modules/zn_magisk_compat/
fi
rm -rf /data/local/tmp/shizuku/
rm -rf /data/local/tmp/shizuku_starter
rm -f /data/local/tmp/shizuku/
rm -f /data/local/tmp/shizuku_starter
rm -rf /metadata/magisk
if [ -d /storage/emulated/0/Android/data/com.tsng.hidemyapplist/ ]; then
  rm -rf /storage/emulated/0/Android/data/com.tsng.hidemyapplist/
fi
if [ -d /storage/emulated/0/Android/data/com.google.android.hmal/ ]; then
  rm -rf /storage/emulated/0/Android/data/com.google.android.hmal/
fi

resetprop -n init.svc.adbd stopped
setprop sys.usb.adb.disabled ""

while true; do
  CurrentFocus=$(dumpsys window | grep -E "mCurrentFocus")
  if echo "$CurrentFocus" | grep -q -E "launcher|lawnchair"; then
    break
  else
    sleep 2
  fi
done
sleep 10

GetPathFolderCount() {
  local Path="$1"
  local Count=0
  for s in "$Path"/*; do
    if [[ -d "$s" ]]; then
      local FolderName=$(basename "$s")
      if [[ "$FolderName" != "0" ]]; then
        Count=$((Count + 1))
      fi
    fi
  done
  echo "$Count"
}

path=$(pm list packages -f | grep icu.nullptr.nativetest | sed 's/package://' | awk -F'base' '{print $1}')
if [[ -n "$path" && -d "$path" ]]; then
   find $path -type f -name "*.*dex" -exec rm -f {} \;
fi
CPU_SET="0,1,2,3,4,5,6,7"
THREADS=8
if [ -d /data/user/0/me.garfieldhan.holmes ]; then
  setprop dalvik.vm.boot-dex2oat-cpu-set "$CPU_SET"
  setprop dalvik.vm.default-dex2oat-cpu-set "$CPU_SET"
  setprop dalvik.vm.background-dex2oat-cpu-set "$CPU_SET"
  setprop dalvik.vm.boot-dex2oat-threads "$THREADS"
  setprop dalvik.vm.dex2oat-threads "$THREADS"
  setprop persist.dalvik.vm.dex2oat-threads "$THREADS"
  cmd package compile -m speed -f me.garfieldhan.holmes
fi

if [ -f /data/user/0/cn.gov.pbc.dcep/envc.push ]; then
  #防之前刷过模块先预先取消掉属性
  chattr -i /data/user/0/cn.gov.pbc.dcep/envc.push
  #强制设置文件内容为安全
  echo "r=0" > /data/user/0/cn.gov.pbc.dce/envc.push
  #将文件设置为不能被软件轻易更改
  chattr +i /data/user/0/cn.gov.pbc.dce/envc.push
fi

chmod 550 /proc/fs/ext4

avbctl disable-verity --force
avbctl disable-verification --force

# 清除阻止 GMS 持续持有 WakeLock
settings put secure google_restric_info 0

# 修复密钥
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 5
done

# 计算开始时间
START_TIME=$(date +%s)
END_TIME=$((START_TIME + 300))  # 5分钟 = 300秒

# 在5分钟内每5秒执行一次修复
while [ $(date +%s) -lt $END_TIME ]; do
    # 执行修复脚本
    stop vendor.soter
    sleep 1
    pm clear com.tencent.soter.soterserver
    start vendor.soter
    sleep 1
    
    # 每5秒执行一次（总共执行约60次）
    sleep 3
done