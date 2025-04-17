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
current_mode=$(getenforce)
if [ "$current_mode" == "Permissive" ]; then
  if [ ${IS_Virtual} == "0" ]; then
    setenforce 1
  fi
fi
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
if [ -d /data/adb/modules/zn_magisk_compat/ ]; then
  rm -rf /data/adb/modules/zn_magisk_compat/
fi
rm -rf /data/local/tmp/shizuku/
rm -rf /data/local/tmp/shizuku_starter
rm -f /data/local/tmp/shizuku/
rm -f /data/local/tmp/shizuku_starter
rm -f /data/swap_config.conf

resetprop -n init.svc.adbd stopped

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

avbctl disable-verity --force
avbctl disable-verification --force

# 如有需要取消注释此代码 OP13
# resetprop -n ro.boot.vbmeta.digest f514511fe0f7e8f2d1b6c5f5e2e9aa062c14314182510b48129eecb3afaa0dbf
# 如有需要取消注释此代码 OP11
# resetprop -n ro.boot.vbmeta.digest 0766a5134c7585f3d27bb743cd51e5fd8fffa78ee48064284695c945650cba98
