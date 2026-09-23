#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
set -eu
umask 077

MODDIR="${0%/*}"
PACKAGE_NAME="li.songe.gkd"
SCRIPT_PATH="/storage/emulated/0/Android/data/li.songe.gkd/files/sh/start.sh"
STATE_DIR="$MODDIR/.state/gkd"
BASELINE_FILE="$STATE_DIR/enabled_accessibility_services.before-module"
ADDED_MARKER="$STATE_DIR/accessibility-added-by-module"
LOG_FILE="$MODDIR/gkd-start.log"
WAIT_SECONDS=300
MODE="${1:---apply}"

log_line() {
    printf '%s\n' "$*"
    mkdir -p "$STATE_DIR"
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

fail() {
    log_line "错误：$*" >&2
    exit 1
}

finish() {
    RESULT=$?
    trap - EXIT
    rmdir "$STATE_DIR/lock" || RESULT=1
    if [ "$RESULT" -ne 0 ]; then
        printf 'GKD 启动失败（退出码 %s），请检查 %s。\n' "$RESULT" "$LOG_FILE" >&2
    fi
    exit "$RESULT"
}

wait_for_start_script() {
    ELAPSED=0
    while [ ! -f "$SCRIPT_PATH" ] && [ "$ELAPSED" -lt "$WAIT_SECONDS" ]; do
        sleep 1
        ELAPSED=$((ELAPSED + 1))
    done
    [ -f "$SCRIPT_PATH" ] || fail "未找到新版 GKD 脚本：$SCRIPT_PATH"
}

find_accessibility_component() {
    COMPONENT=$(dumpsys package "$PACKAGE_NAME" |
        sed -n '/android.accessibilityservice.AccessibilityService:/,/Domain verification status:/p' |
        awk -v prefix="$PACKAGE_NAME/" 'index($2, prefix) == 1 { print $2; exit }')
    [ -n "$COMPONENT" ] || fail "无法从 GKD Manifest 找到无障碍服务组件"
}

enable_accessibility() {
    find_accessibility_component
    CURRENT=$(settings --user 0 get secure enabled_accessibility_services)
    [ "$CURRENT" = "null" ] && CURRENT=""

    if [ ! -e "$BASELINE_FILE" ]; then
        printf '%s\n' "$CURRENT" > "$BASELINE_FILE"
    fi

    case ":$CURRENT:" in
        *":$COMPONENT:"*)
            log_line "新版 GKD 无障碍服务已启用：$COMPONENT"
            return 0
            ;;
    esac

    if [ -n "$CURRENT" ]; then
        UPDATED="$CURRENT:$COMPONENT"
    else
        UPDATED="$COMPONENT"
    fi
    settings --user 0 put secure enabled_accessibility_services "$UPDATED" || fail "写入 GKD 无障碍服务失败"
    settings --user 0 put secure accessibility_enabled 1 || fail "启用无障碍总开关失败"
    VERIFY=$(settings --user 0 get secure enabled_accessibility_services)
    case ":$VERIFY:" in
        *":$COMPONENT:"*)
            : > "$ADDED_MARKER"
            log_line "已启用新版 GKD 无障碍服务：$COMPONENT"
            ;;
        *) fail "GKD 无障碍服务写入后读回不一致" ;;
    esac
}

restore_accessibility() {
    if [ ! -f "$BASELINE_FILE" ]; then
        log_line "没有 GKD 无障碍基线，跳过回滚"
        return 0
    fi
    if [ ! -e "$ADDED_MARKER" ]; then
        log_line "GKD 无障碍服务原本已启用，保留现状"
        return 0
    fi
    ORIGINAL=$(cat "$BASELINE_FILE")
    settings --user 0 put secure enabled_accessibility_services "$ORIGINAL" || fail "回滚 GKD 无障碍服务失败"
    if [ -z "$ORIGINAL" ]; then
        settings --user 0 put secure accessibility_enabled 0 || true
    fi
    rm -f "$ADDED_MARKER"
    log_line "已恢复 GKD 无障碍服务初始列表"
}

apply() {
    [ "$(id -u)" = "0" ] || fail "需要 root 权限"
    pm path "$PACKAGE_NAME" >/dev/null 2>&1 || { log_line "$PACKAGE_NAME 未安装，跳过"; return 0; }
    wait_for_start_script
    /system/bin/sh "$SCRIPT_PATH" || fail "GKD 官方 start.sh 执行失败"
    enable_accessibility
    log_line "GKD v$(dumpsys package "$PACKAGE_NAME" | sed -n 's/.*versionName=//p' | head -n 1) 启动完成"
}

case "$MODE" in
    --apply|--boot|--restore) ;;
    *) printf '用法：%s [--apply|--boot|--restore]\n' "$0" >&2; exit 2 ;;
esac

mkdir -p "$STATE_DIR"
if ! mkdir "$STATE_DIR/lock"; then
    printf '已有 GKD 启动实例运行或残留锁：%s/lock\n' "$STATE_DIR" >&2
    exit 1
fi
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
: > "$LOG_FILE"

case "$MODE" in
    --restore) restore_accessibility ;;
    --boot)
        sleep 15
        apply
        ;;
    --apply) apply ;;
esac
