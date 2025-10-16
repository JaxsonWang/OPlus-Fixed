#!/system/bin/sh
MODDIR=${0%/*}

LOG_DIR="${MODDIR}/log.txt"

# 删除日志文件
if [ -f $LOG_DIR ]; then
    rm -rf $LOG_DIR
fi

chmod 755 "$MODDIR/fix_soter_key.sh"

# Check if the script is running as root
chmod 777 $MODDIR/bash
$MODDIR/bash $MODDIR/main.sh

# Google CN GMS Features
mount --bind $MODDIR/my_product/etc/permissions/oplus_google_cn_gms_features.xml /my_product/etc/permissions/oplus_google_cn_gms_features.xml
mount --bind $MODDIR/my_product/etc/permissions/oplus.feature.control_cn_gms.xml /my_product/etc/permissions/oplus.feature.control_cn_gms.xml
