#!/bin/sh

# OPlus-Fixed Action Script
# Executed via KernelSU WebUI or manually via adb shell

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

echo "=========================================="
echo "OPlus-Fixed v$(grep versionCode $MODDIR/module.prop | sed 's/versionCode=//g')"
echo "开始执行修复..."
echo "=========================================="
echo ""

# Check if running in WebUI mode (non-interactive)
# WebUI detected if no TTY is connected
if [ ! -t 0 ]; then
    WEBUI_MODE=1
fi

echo "[1/3] 设置脚本权限..."
chmod 755 "$MODDIR/soter-fixed.sh" && echo "✓ soter-fixed.sh 权限设置成功" || echo "✗ soter-fixed.sh 权限设置失败"
chmod 755 "$MODDIR/clear-fixed.sh" && echo "✓ clear-fixed.sh 权限设置成功" || echo "✗ clear-fixed.sh 权限设置失败"
chmod 755 "$MODDIR/prop.sh" && echo "✓ prop.sh 权限设置成功" || echo "✗ prop.sh 权限设置失败"
echo ""

echo "[2/3] 清除检测痕迹和日志..."
sh "$MODDIR/clear-fixed.sh"
if [ $? -eq 0 ]; then
    echo "✓ 检测痕迹清除完成"
else
    echo "✗ 检测痕迹清除失败"
fi
echo ""

echo "[2/3] 重置系统属性..."
sh "$MODDIR/prop.sh"
if [ $? -eq 0 ]; then
    echo "✓ 系统属性重置完成"
else
    echo "✗ 系统属性重置失败"
fi
echo ""

echo "[3/3] 重启 SOTER 服务..."
sh "$MODDIR/soter-fixed.sh"
if [ $? -eq 0 ]; then
    echo "✓ SOTER 服务修复完成"
else
    echo "✗ SOTER 服务修复失败"
fi
echo ""

echo "=========================================="
echo "所有操作执行完成！"
echo "=========================================="
echo ""

# WebUI 模式不自动退出
if [ "$WEBUI_MODE" = "1" ]; then
    echo "WebUI 模式：执行结束"
else
    echo "执行结束"
    sleep 3
    echo "运行结束"
fi
