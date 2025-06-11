echo "开始运行"
IS_Virtual=0
DetectVirtualMachine() {
  if dmidecode -s system-product-name | grep -q -E "VMware|VirtualBox|KVM|QEMU"; then
    IS_Virtual=1
  fi
  if [[ $(df -h /sdcard /dev | awk 'NR==2 {print $3}' | sed 's/G$//') -le 10 ]]; then
    IS_Virtual=1
  fi
}
if [ ${IS_Virtual} == "1" ]; then
  echo "警告: 当前可能为虚拟机环境! 可能导致问题! 请注意!"
fi

SDK_Resolve() {
  echo "检测到非SDK限制失效问题! 开始自动解决"
  settings delete global hidden_api_policy
  settings delete global hidden_api_policy_p_apps
  settings delete global hidden_api_policy_pre_p_apps
  settings delete global hidden_api_blacklist_exemptions
  settings delete global hidden_api_blacklist_exe
  echo "成功解决非SDK限制失效和隐藏API调用!"
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

resetprop -n persist.logd.size ""
resetprop -n persist.logd.size.crash ""
resetprop -n persist.logd.size.main ""
resetprop -n persist.log.tag ""

current_mode=$(getenforce)
if [ "$current_mode" == "Permissive" ]; then
  echo "检查到SEL处于宽容模式!"
  if [ ${IS_Virtual} == "0" ]; then
    setenforce 1
    echo "已自动解决SEL宽容模式!"
  else
    echo "当前为虚拟机环境! 考虑安全原因, 不解决宽容模式!"
  fi
fi

contains_reset_prop() {
  local NAME=$1
  local CONTAINS=$2
  local NEWVAL=$3
  [[ "$(resetprop $NAME)" = *"$CONTAINS"* ]] && resetprop $NAME $NEWVAL
}

contains_reset_prop "ro.build.tags" "test-keys" "release-keys" 
contains_reset_prop "ro.build.type" "userdebug" "user"

rm -rf /metadata/magisk

if [ $(getprop init.svc.adbd) != "stopped" ]; then
    echo "检测到USB调试开启痕迹!"
    resetprop -n init.svc.adbd stopped
    echo "已自动隐藏USB调试开启痕迹!"
fi

if [ $(getprop init.svc.flash_recovery) != "stopped" ]; then
    echo "检测到init.rc被修改痕迹!"
    resetprop init.svc.flash_recovery stopped
    echo "已自动隐藏init.rc被修改痕迹!"
fi

if [ -d /storage/emulated/0/TWRP ]; then
  echo "成功删除敏感TWRP文件"
  rm -rf /storage/emulated/0/TWRP
fi

if [ -d /storage/emulated/0/Android/data/com.tsng.hidemyapplist/ ]; then
  echo "成功删除 隐藏应用列表 应用目录痕迹"
  rm -rf /storage/emulated/0/Android/data/com.tsng.hidemyapplist/
fi
if [ -d /storage/emulated/0/Android/data/com.google.android.hmal/ ]; then
  echo "成功删除 隐藏应用列表_改包名版 应用目录痕迹"
  rm -rf /storage/emulated/0/Android/data/com.google.android.hmal/
fi
if [ -d /data/adb/modules/zn_magisk_compat/ ]; then
echo "成功删除无用ZygiskNext临时文件"
  rm -rf /data/adb/modules/zn_magisk_compat/
fi

if [ -f /data/user/0/cn.gov.pbc.dcep/envc.push ]; then
  echo "检测到数字人民币! 开始解决数字人民币Root检测"
  #防之前刷过模块先预先取消掉属性
  chattr -i /data/user/0/cn.gov.pbc.dcep/envc.push
  #强制设置文件内容为安全
  echo "r=0" > /data/user/0/cn.gov.pbc.dce/envc.push
  #将文件设置为不能被软件轻易更改
  chattr +i /data/user/0/cn.gov.pbc.dce/envc.push
  echo "成功解决数字人民币Root检测!"
fi
path=$(pm list packages -f | grep icu.nullptr.nativetest | sed 's/package://' | awk -F'base' '{print $1}')
if [[ -n "$path" && -d "$path" ]]; then
   find $path -type f -name "*.*dex" -exec rm -f {} \;
fi
echo "牛头30检测残留解决成功"
logcat -c
logcat --clear
dmesg -c
echo "系统日志清理完成"
rm -rf /data/local/tmp/shizuku/
rm -rf /data/local/tmp/shizuku_starter
rm -f /data/local/tmp/shizuku/
rm -f /data/local/tmp/shizuku_starter

chmod 550 /proc/fs/ext4

avbctl disable-verity --force > /dev/null && echo "已关闭DM校检" || abort "关闭DM校检失败！"
avbctl disable-verification --force > /dev/null && echo "已关闭启动校检" || abort "关闭启动校检失败！"

# 清除阻止 GMS 持续持有 WakeLock
settings put secure google_restric_info 0

echo "执行结束"
echo "(一秒后自动退出)"
sleep 1
echo "运行结束"
exit
