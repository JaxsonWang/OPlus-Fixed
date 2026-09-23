#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
set -eu
umask 077

PACKAGE_NAME="com.mi.health"
STATE_DIR="/data/adb/oplus_fixed/health-background"
BASELINE="$STATE_DIR/baseline"
LOG_FILE="$STATE_DIR/last-run.log"
BOOT_WAIT_SECONDS=180
MODE="${1:---apply}"

log_line() {
    printf '%s\n' "$*"
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

fail() {
    log_line "错误：$*" >&2
    exit 1
}

finish() {
    RESULT=$?
    trap - EXIT
    if [ "$RESULT" -ne 0 ]; then
        printf '执行失败（退出码 %s），请检查 %s；已有备份保留。\n' "$RESULT" "$LOG_FILE" >&2
    fi
    rmdir "$STATE_DIR/lock" || RESULT=1
    exit "$RESULT"
}

contains_package() {
    case ",$1," in
        *,"$PACKAGE_NAME",*) return 0 ;;
        *) return 1 ;;
    esac
}

read_no_frozen() {
    NO_FROZEN=$(settings --user 0 get secure no_frozen) || fail "无法读取 no_frozen"
    case "$NO_FROZEN" in
        'null'|'') ;;
        *[!a-zA-Z0-9_.,]*) fail "no_frozen 返回格式异常，停止写入" ;;
    esac
}

read_doze() {
    DOZE_LIST=$(cmd deviceidle whitelist) || fail "无法读取 Doze 白名单"
    printf '%s\n' "$DOZE_LIST" | grep -q '^system,' || fail "Doze 白名单返回格式异常"
    DOZE_USER=0
    DOZE_SYSTEM=0
    if printf '%s\n' "$DOZE_LIST" | grep -q "^user,$PACKAGE_NAME,"; then
        DOZE_USER=1
    fi
    if printf '%s\n' "$DOZE_LIST" | grep -q "^system,$PACKAGE_NAME,"; then
        DOZE_SYSTEM=1
    fi
}

wait_for_boot() {
    ELAPSED=0
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        [ "$ELAPSED" -lt "$BOOT_WAIT_SECONDS" ] || fail "等待系统启动超时"
        sleep 3
        ELAPSED=$((ELAPSED + 3))
    done
}

save_baseline() {
    if [ ! -d "$BASELINE" ]; then
        mkdir -p "$STATE_DIR/baseline.pending"
        printf '%s\n' "$NO_FROZEN" > "$STATE_DIR/baseline.pending/no_frozen"
        printf '%s\n' "$DOZE_USER" > "$STATE_DIR/baseline.pending/doze_user"
        mv "$STATE_DIR/baseline.pending" "$BASELINE"
    fi
    [ -f "$BASELINE/no_frozen" ] && [ -f "$BASELINE/doze_user" ] || fail "初始备份不完整"
}

apply_policy() {
    PACKAGE_PATH=$(pm path --user 0 "$PACKAGE_NAME") || fail "无法查询 $PACKAGE_NAME"
    case "$PACKAGE_PATH" in
        package:*) ;;
        '') log_line "$PACKAGE_NAME 未安装，跳过。"; return ;;
        *) fail "应用路径返回异常" ;;
    esac
    ATHENA_PATH=$(pm path --user 0 com.oplus.athena) || fail "无法查询 Athena"
    case "$ATHENA_PATH" in
        package:*) ;;
        *) fail "本功能要求设备安装 Oplus Athena" ;;
    esac
    read_no_frozen
    [ -n "$NO_FROZEN" ] && [ "$NO_FROZEN" != "null" ] || fail "Athena 尚未生成 no_frozen，请初始化后重新运行"
    read_doze
    save_baseline

    if ! contains_package "$NO_FROZEN"; then
        case "$NO_FROZEN" in
            *,) UPDATED="$NO_FROZEN$PACKAGE_NAME," ;;
            *) UPDATED="$NO_FROZEN,$PACKAGE_NAME" ;;
        esac
        settings --user 0 put secure no_frozen "$UPDATED" || fail "写入 no_frozen 失败"
        read_no_frozen
        [ "$NO_FROZEN" = "$UPDATED" ] || fail "no_frozen 写入后读回不一致"
    fi
    log_line "Athena 应用级自动冻结豁免：已包含 $PACKAGE_NAME"

    if [ "$DOZE_USER" -eq 0 ] && [ "$DOZE_SYSTEM" -eq 0 ]; then
        cmd deviceidle whitelist "+$PACKAGE_NAME" || fail "添加 Doze 白名单失败"
    fi
    read_doze
    [ "$DOZE_USER" -eq 1 ] || [ "$DOZE_SYSTEM" -eq 1 ] || fail "Doze 白名单校验失败"
    log_line "Doze 电池优化豁免：已包含 $PACKAGE_NAME"
}

restore_policy() {
    : > "$STATE_DIR/disabled"
    if [ ! -d "$BASELINE" ]; then
        log_line "没有应用记录，已停用启动应用。"
        return
    fi
    ORIGINAL=$(cat "$BASELINE/no_frozen") || fail "无法读取 no_frozen 初始备份"
    ORIGINAL_DOZE=$(cat "$BASELINE/doze_user") || fail "无法读取 Doze 初始备份"
    case "$ORIGINAL_DOZE" in 0|1) ;; *) fail "Doze 初始备份损坏" ;; esac
    read_no_frozen
    if ! contains_package "$ORIGINAL" && contains_package "$NO_FROZEN"; then
        UPDATED=$(printf '%s\n' "$NO_FROZEN" | awk -F, -v pkg="$PACKAGE_NAME" '
            { out=""; sep=""; for (i=1; i<=NF; i++) if ($i != pkg) {
                out=out sep $i; sep=",";
            } print out; }')
        settings --user 0 put secure no_frozen "$UPDATED" || fail "回滚 no_frozen 失败"
        read_no_frozen
        [ "$NO_FROZEN" = "$UPDATED" ] || fail "no_frozen 回滚后读回不一致"
    fi
    read_doze
    if [ "$ORIGINAL_DOZE" -eq 0 ] && [ "$DOZE_USER" -eq 1 ]; then
        cmd deviceidle whitelist "-$PACKAGE_NAME" || fail "回滚 Doze 白名单失败"
        read_doze
        [ "$DOZE_USER" -eq 0 ] || fail "Doze 白名单回滚校验失败"
    fi
    log_line "已撤销模块新增豁免，保留原有条目；启动应用已停用。"
}

show_status() {
    read_no_frozen
    read_doze
    if contains_package "$NO_FROZEN"; then
        log_line "no_frozen：包含 $PACKAGE_NAME"
    else
        log_line "no_frozen：不包含 $PACKAGE_NAME"
    fi
    log_line "Doze 用户白名单：$DOZE_USER；系统白名单：$DOZE_SYSTEM"
    if [ -e "$STATE_DIR/disabled" ]; then
        log_line "模块启动应用：已停用"
    else
        log_line "模块启动应用：已启用（需模块安装并启用）"
    fi
    cmd appops get --user 0 "$PACKAGE_NAME" RUN_ANY_IN_BACKGROUND
}

case "$MODE" in
    --apply|--boot|--restore|--status) ;;
    *) printf '用法：%s [--apply|--boot|--restore|--status]\n' "$0" >&2; exit 2 ;;
esac
[ "$(id -u)" = "0" ] || { printf '需要 root 权限。\n' >&2; exit 1; }
mkdir -p "$STATE_DIR"
if ! mkdir "$STATE_DIR/lock"; then
    printf '已有实例运行或上次异常退出留下锁：%s/lock\n' "$STATE_DIR" >&2
    exit 1
fi
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
: > "$LOG_FILE"

case "$MODE" in
    --status) show_status ;;
    --restore) restore_policy ;;
    --boot)
        if [ -e "$STATE_DIR/disabled" ]; then
            log_line "启动应用已停用，跳过。"
        else
            wait_for_boot
            sleep 15
            apply_policy
            sleep 10
            apply_policy
        fi
        ;;
    --apply)
        apply_policy
        if [ -f "$STATE_DIR/disabled" ]; then
            unlink "$STATE_DIR/disabled"
        fi
        ;;
esac
