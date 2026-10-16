#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH

ui_print "Module Version: $(sed -n 's/^version=//p' "$MODPATH/module.prop")"
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

# Replace applications through the root manager's standard module mount.
REPLACE="
/system/product/app/Browser
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
ui_print "*** 音量上键 (+) = 安装 ***"
ui_print "*** 音量下键 (-) = 忽略 ***"

select_optional_feature() {
    FEATURE_NAME=$1
    FEATURE_MARKER=$2

    ui_print ""
    ui_print "*** 是否安装 ${FEATURE_NAME} ***"
    ui_print "*** 请使用音量按键选择：安装或者忽略安装 ***"
    if chooseport 20 "NO"; then
        rm -f "$FEATURE_MARKER"
        ui_print "${FEATURE_NAME}已选择安装！"
    else
        : > "$FEATURE_MARKER"
        ui_print "${FEATURE_NAME}已忽略！"
    fi
}

select_optional_feature "小米健康后台保活" "$MODPATH/health-background.disabled"
select_optional_feature "GKD 启动兼容" "$MODPATH/gkd.disabled"

ui_print ""
ui_print "*** 是否安装原生 120Hz / 165Hz 切换 ***"
ui_print "+ 重启后，在系统设置的“刷新率设定”中选择 120Hz 或极速高刷 165Hz。"
ui_print "+ 扩展应用高刷支持，保留智能切换、60/90Hz 档及温控。"
ui_print "+ 耗电和发热可能增加；应用自身锁帧及单独设置仍会影响实际帧率。"
ui_print "*** 音量上键安装；音量下键或 20 秒超时忽略 ***"
if chooseport 20 "NO"; then
    if ! dumpsys display | grep -Eq 'fps=165([.]0+)?[,}]'; then
        abort "+ [165Hz] 未检测到原生 165Hz 显示模式，停止安装。"
    fi
    chmod 755 "$MODPATH/refresh-rate-165.sh"
    /system/bin/sh "$MODPATH/refresh-rate-165.sh" --prepare || abort "+ [165Hz] 配置生成失败，停止安装。"
    # 交给 Root 管理器加载模块属性；不写 persist 属性的持久化存储。
    printf '%s\n' \
        'persist.performance.rapid.refresh_rate.level=165' \
        'persist.performance.rapid.refresh_rate.is_perf_mode=true' \
        >> "$MODPATH/system.prop" || abort "+ [165Hz] 无法保存原生菜单配置。"
    : > "$MODPATH/refresh-rate-165.enabled" || abort "+ [165Hz] 无法保存安装选项。"
    ui_print "+ [165Hz] 已选择安装，重启后生效。"
else
    rm -f "$MODPATH/refresh-rate-165.enabled" || abort "+ [165Hz] 无法保存跳过选项。"
    ui_print "+ [165Hz] 已忽略，不修改刷新率策略。"
fi

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
    ui_print "Unlock CN GMS 模块已忽略！"
fi

ui_print ""
ui_print "模块安装完成! 重启生效"
