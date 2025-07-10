MODDIR=${0%/*}
SOURCE_DIR="${MODDIR}/opex"
TARGET_DIR="/mnt/opex"
LOG_DIR="${MODDIR}/log.txt"
OPEX_RESULT="/data/oplus/os/opex/OpexResult"

# 确保日志文件存在且可写
touch "$LOG_DIR" 2>/dev/null || { echo "错误：无法创建日志文件" >&2; exit 1; }

# 日志函数用于统一记录
log() {
    local level=$1
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*" >> "$LOG_DIR"
}

# 解析配置文件
parse_config() {
    mapfile -t mount_paths < <(grep 'ovlMountPath' $1 | 
                              sed 's|.*"/\([^"]*\).*|/\1|;s|/$||')
}

# 挂载初始目录
#if ! su -c mount --bind "${MODDIR}/anymount/mount" "/data/oplus/os/opex/mount" 2>>"$LOG_DIR"; then
#    log ERROR "挂载anymount目录失败"
#    exit 1
#fi

# 处理.img镜像文件
find "$SOURCE_DIR" -maxdepth 1 -type f -name "*.img" | while IFS= read -r img_file; do
    base_name=${img_file##*/} base_name=${base_name%.img}
    mount_name=${base_name%_*}@${base_name##*_}
    ota_name=${base_name%_*}/${base_name##*_}
    
    mount_point="$TARGET_DIR/$mount_name"
    mkdir -p "$mount_point" 2>>"$LOG_DIR" || { log ERROR "创建挂载点失败: $mount_point"; continue; }
    
    # 挂载镜像文件
    if su -c mount -t ext4 -o ro,dirsync,seclabel,nodev,noatime "$img_file" "$mount_point" 2>>"$LOG_DIR"; then
        log INFO "成功挂载: $img_file -> $mount_point"
    else
        log ERROR "挂载失败: $img_file"
        rmdir "$mount_point" 2>/dev/null
        continue
    fi

    # 写入OPEX执行结果
    echo "s/$ota_name/0/NULL" >>"$OPEX_RESULT" 2>>"$LOG_DIR" || log ERROR "写入OPEX_RESULT失败"

    # 解析配置并处理覆盖挂载
    parse_config "$mount_point/opex.cfg"

    for path in "${mount_paths[@]}"; do
        log DEBUG $path
        overlay_dir="$mount_point$path"
        options="ro,seclabel,noatime,lowerdir=${overlay_dir}:${path},redirect_dir=on"
        
        log INFO "正在挂载覆盖层: $path"
        if su -c mount -t overlay overlay "$path" -o "$options" 2>>"$LOG_DIR"; then
            log INFO "成功挂载覆盖层: $path"
        else
            log ERROR "覆盖层挂载失败: $path"
            su -c umount "$mount_point" 2>>"$LOG_DIR"
            rmdir "$mount_point" 2>/dev/null
            continue 2
        fi
    done
done
