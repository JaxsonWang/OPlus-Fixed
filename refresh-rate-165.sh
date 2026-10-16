#!/bin/sh

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
MODDIR=${0%/*}
OVERLAY="$MODDIR/refresh-rate-165"

fail() {
    echo "+ [165Hz] $*" >&2
    return 1
}

prepare_configs() {
    local STAGING TARGET
    STAGING=$(mktemp -d "$MODDIR/.refresh-rate-165.XXXXXX") || return 1
    for TARGET in /my_product/etc/refresh_rate_config.xml \
        /data/system/refresh_rate_config.xml; do
        # 数据分区副本由系统按需生成，不创建原本不存在的系统文件。
        case "$TARGET" in
            /data/*) [ -f "$TARGET" ] || continue ;;
        esac
        if ! mkdir -p "$STAGING$(dirname "$TARGET")" ||
            ! cp -p "$TARGET" "$STAGING$TARGET" ||
            ! awk -f "$MODDIR/refresh-rate-165.awk" "$TARGET" > "$STAGING$TARGET"; then
            rm -rf "$STAGING"
            fail "无法生成配置：${TARGET}，请检查文件与格式。"
            return 1
        fi
        # bind 后使用源文件的标签；否则 system_server 可能被 SELinux 拒绝读取。
        if ! chcon "$(stat -c %C "$TARGET")" "$STAGING$TARGET"; then
            rm -rf "$STAGING"
            fail "无法设置配置权限或 SELinux 标签：$TARGET"
            return 1
        fi
        if ! printf '%s\n' "$TARGET" >> "$STAGING/targets"; then
            rm -rf "$STAGING"
            fail "无法保存挂载清单。"
            return 1
        fi
    done
    # 仅替换本模块生成的副本，手机原文件从未被写入。
    if ! rm -rf "$OVERLAY" || ! mv "$STAGING" "$OVERLAY"; then
        rm -rf "$STAGING"
        fail "无法保存模块配置。"
        return 1
    fi
}

mount_configs() {
    local TARGET MOUNTED="" PREVIOUS
    [ -f "$MODDIR/refresh-rate-165.enabled" ] || return 0
    # 每次开机从当前系统版本生成，避免 OTA 或云端配置更新后使用旧副本。
    prepare_configs || return 1
    while IFS= read -r TARGET; do
        if ! mount --bind "$OVERLAY$TARGET" "$TARGET"; then
            fail "挂载失败：${TARGET}，撤销本次已完成的挂载。"
            for PREVIOUS in $MOUNTED; do
                umount "$PREVIOUS" || fail "撤销挂载失败：${PREVIOUS}；请禁用模块并重启。"
            done
            return 1
        fi
        MOUNTED="$TARGET $MOUNTED"
        echo "+ [165Hz] 已挂载 $TARGET"
    done < "$OVERLAY/targets"
}

unmount_configs() {
    local TARGET
    [ -f "$OVERLAY/targets" ] || return 0
    while IFS= read -r TARGET; do
        # mountinfo 的 root 字段指向模块副本，只卸载本模块拥有的挂载。
        if awk -v target="$TARGET" -v suffix="/oplus_fixed/refresh-rate-165$TARGET" '
            $5 == target {
                found = length($4) >= length(suffix) &&
                    substr($4, length($4) - length(suffix) + 1) == suffix
            }
            END { exit !found }
        ' /proc/self/mountinfo; then
            umount "$TARGET" || return 1
        fi
    done < "$OVERLAY/targets"
}

case "$1" in
    --prepare) prepare_configs ;;
    --mount) mount_configs ;;
    --unmount) unmount_configs ;;
    *) fail "用法：$0 --prepare|--mount|--unmount"; exit 1 ;;
esac
