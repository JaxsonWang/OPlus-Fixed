#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH

ui_print "Moduel Version: $(grep versionCode $MODPATH/module.prop | sed 's/versionCode=//g')"
ui_print "Android Version: $(getprop ro.build.version.release)"
ui_print "API Version: $(getprop ro.product.cpu.abi)"
ui_print "Software Version: $(getprop ro.build.display.id.show)"

if [ "$KSU" ]; then
  ui_print "Root Type: KSU/AP"
else
  ui_print "Root Type: Magisk"
fi
ui_print "Root Version: $MAGISK_VER_CODE"
ui_print "MODPATH: $MODPATH"

# Remove applications
REPLACE="
/system/product/app/Browser
"

# 创建文件 skip_mount 文件
# 不能直接挂载，会造成环境泄露
# 需要使用 mount --bind 挂载
# 但我这边没有做 magisk 模块兼容
[ ! -f $MODPATH/skip_mount ] && touch $MODPATH/skip_mount

echo "$REPLACE" | while read -r path; do
    if [ -n "$path" ]; then
        {
            echo ""
            echo "# Remove $path"
            echo "mount --bind \$MODDIR$path $path"
        } >> "$MODPATH/post-fs-data.sh"
    fi
done


chooseport() {
    [ -n "$1" ] && local DELAY=$1 || local DELAY=10
    [ "$2" = "YES" ] && local DEFAULT=$2 || local DEFAULT="NO"
    local START_TIMESTAMP=$(date +%s)
    local REMAINING_DELAY=$DELAY

    ui_print "请在 $DELAY 秒内回答，否则将默认为 $DEFAULT"

    while [ "$REMAINING_DELAY" -gt 0 ]; do
        timeout ${REMAINING_DELAY}s /system/bin/getevent -lqc 1 2>&1 > $TMPDIR/events &
        wait $! 2>/dev/null # 隐藏 "Terminated" 消息
        if grep -q 'KEY_VOLUMEUP *DOWN' $TMPDIR/events; then
            ui_print "音量增加 (+) = 检测到 YES！"
            return 0 # 0 = true
        elif grep -q 'KEY_VOLUMEDOWN *DOWN' $TMPDIR/events; then
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
ui_print "*** 是否安装 Unlock CN GMS 模块 ***"
ui_print ""
if chooseport 20 "NO"; then
    origin=/my_product/etc/permissions/oplus_google_cn_gms_features.xml
    target="$MODPATH/my_product/etc/permissions/oplus_google_cn_gms_features.xml"

    {
        echo ""
        echo "# Unlock CN GMS mount"
        echo "mount --bind \$MODDIR/my_product/etc/permissions/oplus_google_cn_gms_features.xml /my_product/etc/permissions/oplus_google_cn_gms_features.xml"
    } >> "$MODPATH/post-fs-data.sh"

    # 拷贝并修改 XML 文件
    mkdir -p "$(dirname "$target")"
    cp -f "$origin" "$target"
    sed -i '/cn.google.services/d' "$target"
    sed -i '/services_updater/d' "$target"

    ui_print "modify $origin"
    ui_print "Unlock CN GMS 模块已添加安装！"
else
    # sed -i '/\/my_product\/etc\/permissions\/oplus_google_cn_gms_features.xml/d' $MODPATH/post-fs-data.sh
    # sed -i '/\/my_product\/etc\/permissions\/oplus.feature.control_cn_gms.xml/d' $MODPATH/post-fs-data.sh
    # sed -i '/google_restric_info/d' $MODPATH/action.sh
    # sed -i '/google_restric_info/d' $MODPATH/service.sh
    ui_print "Unlock CN GMS 模块已忽略！"
fi

ui_print ""
ui_print "*** 是否开启 iPhone 互联特征 ***"
ui_print ""
if chooseport 20 "NO"; then
    origin=/my_product/etc/extension/com.oplus.oplus-feature.xml
    target="$MODPATH/my_product/etc/extension/com.oplus.oplus-feature.xml"

    {
        echo ""
        echo "# 解锁 iPhone 互联特征"
        echo "mount --bind \$MODDIR/my_product/etc/extension/com.oplus.oplus-feature.xml /my_product/etc/extension/com.oplus.oplus-feature.xml"
    } >> "$MODPATH/post-fs-data.sh"

    # 拷贝并修改 XML 文件
    mkdir -p "$(dirname "$target")"
    cp -f "$origin" "$target"
    sed -i '/<\/oplus-config>/i \	<oplus-feature name="oplus.software.radio.hfp_comm_shared_support"/>' "$target"

    ui_print "modify $origin"
    ui_print "iPhone 互联特征已开启！"
else
    ui_print "iPhone 互联特征已忽略！"
fi

ui_print ""
ui_print "模块安装完成! 重启生效"