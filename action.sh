#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

echo "=========================================="
echo "OPlus-Fixed v$(grep versionCode "$MODDIR/module.prop" | sed 's/versionCode=//g')"
echo "开始按安装选项应用小米健康保活并启动 GKD..."
echo "=========================================="
echo ""

HEALTH_STATUS=0
GKD_STATUS=0

if [ -e "$MODDIR/health-background.disabled" ]; then
    echo "+ 小米健康后台保活已忽略，跳过。"
else
    echo "+ 应用 com.mi.health 后台保活策略..."
    /system/bin/sh "$MODDIR/health-background-fix.sh" --apply
    HEALTH_STATUS=$?
    if [ "$HEALTH_STATUS" -ne 0 ]; then
        echo "后台豁免应用失败（退出码 $HEALTH_STATUS），继续检查 GKD。"
    fi
fi
echo ""

if [ -e "$MODDIR/gkd.disabled" ]; then
    echo "+ GKD 启动兼容已忽略，跳过。"
else
    /system/bin/sh "$MODDIR/gkd-start.sh" --apply
    GKD_STATUS=$?
fi

echo ""
if [ -e "$MODDIR/gkd.disabled" ]; then
    echo "GKD 启动兼容已跳过"
elif [ "$GKD_STATUS" -eq 0 ]; then
    echo "GKD 启动脚本执行完成"
else
    echo "GKD 启动脚本执行失败"
fi

echo "2 秒后退出"
sleep 2

if [ "$HEALTH_STATUS" -ne 0 ]; then
    exit "$HEALTH_STATUS"
fi
exit "$GKD_STATUS"
