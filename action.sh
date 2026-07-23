#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

echo "=========================================="
echo "OPlus-Fixed v$(grep versionCode "$MODDIR/module.prop" | sed 's/versionCode=//g')"
echo "开始执行 GKD 启动脚本..."
echo "=========================================="
echo ""

sh "$MODDIR/gkd-start.sh"
STATUS=$?

echo ""
if [ "$STATUS" -eq 0 ]; then
    echo "GKD 启动脚本执行完成"
else
    echo "GKD 启动脚本执行失败"
fi

echo "2 秒后退出"
sleep 2

exit "$STATUS"
