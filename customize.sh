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

chooseport() {
    [ -n "$1" ] && local DELAY=$1 || local DELAY=10
    [ "$2" = "YES" ] && local DEFAULT=$2 || local DEFAULT="NO"
    local START_TIMESTAMP=$(date +%s)
    local REMAINING_DELAY=$DELAY

    ui_print "请在 $DELAY 秒内回答，否则将默认为 $DEFAULT"

    while [ "$REMAINING_DELAY" -gt 0 ]; do
        timeout ${REMAINING_DELAY}s /system/bin/getevent -lqc 1 2>&1 > $TMPDIR/events &
        wait $! 2>/dev/null # 隐藏 "Terminated" 消息
        if (`grep -q 'KEY_VOLUMEUP *DOWN' $TMPDIR/events`); then
            ui_print "音量增加 (+) = 检测到 YES！"
            return 0 # 0 = true
        elif (`grep -q 'KEY_VOLUMEDOWN *DOWN' $TMPDIR/events`); then
            ui_print "音量减少 (-) = 检测到 NO！"
            return 1 # 1 = false
        fi
        REMAINING_DELAY=$(($START_TIMESTAMP + $DELAY - $(date +%s)))
    done

    ui_print "未检测到音量键操作..."
    if [ "$DEFAULT" = "YES" ] ; then
        ui_print "音量增加 (+) = 默认为 YES！"
        return 0 # 0 = true
    else
        ui_print "音量减少 (-) = 默认为 NO！"
        return 1 # 1 = false
    fi
}

ui_print ""
ui_print "+ 模块个性化配置"
ui_print ""
ui_print "*** 请使用音量按键选择 ***"
ui_print "*** 音量上键 (+) = 是 ***"
ui_print "*** 音量上键 (-) = 否 ***"

ui_print ""
ui_print "*** 是否安装 Android Auto 伪装模块 ***"
ui_print ""
if chooseport 20 "NO"; then # 0 = True, why shell why..
    ui_print "Android Auto 伪装模块已添加安装！"
else
    rm -r $MODPATH/system/product/app/GoogleTTS
    rm -r $MODPATH/system/product/app/Maps
    rm -r $MODPATH/system/product/priv-app/Velvet
    ui_print "Android Auto 伪装模块已忽略"！
fi

ui_print ""
ui_print "*** 是否安装 Unlock CN GMS 模块 ***"
ui_print ""
if chooseport 20 "NO"; then # 0 = True, why shell why..
    ui_print "Unlock CN GMS 模块已添加安装！"
else
    rm -r $MODPATH/my_bigball
    sed -i '/\/my_bigball\/etc\/permissions\/oplus_google_cn_gms_features.xml/d' $MODPATH/post-fs-data.sh
    sed -i '/\/my_bigball\/etc\/permissions\/oplus.feature.control_cn_gms.xml/d' $MODPATH/post-fs-data.sh
    ui_print "Unlock CN GMS 模块已忽略"！
fi

ui_print ""
if [ -d /data/adb/modules/tricky_store ]; then
  ui_print "- keybox 安装成功！"
  mkdir -p /data/adb/tricky_store
  mv $MODPATH/keybox.xml /data/adb/tricky_store
else
  ui_print "- TrickyStore 模块没有安装！"
fi

# 暂时删除无用代码
rm -r $MODPATH/my_product

chcon -r u:object_r:system_file:s0 $MODPATH/system
set_perm_recursive $MODPATH  0  0  0755  0644
set_perm_recursive $MODPATH/system/bin  0  2000  0755 0755 u:object_r:same_process_hal_file:s0

ui_print ""