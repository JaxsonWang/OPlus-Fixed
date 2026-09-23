#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR="${0%/*}"

# 持久化设置不会随模块目录删除而消失，卸载前撤销本模块新增的豁免。
/system/bin/sh "$MODDIR/health-background-fix.sh" --restore
/system/bin/sh "$MODDIR/gkd-start.sh" --restore
