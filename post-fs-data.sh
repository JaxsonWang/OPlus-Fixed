#!/system/bin/sh
MODDIR=${0%/*}

mount --bind $MODDIR/my_product/etc/extension/com.oplus.app-features.xml /my_product/etc/extension/com.oplus.app-features.xml
mount --bind $MODDIR/my_product/etc/extension/com.oplus.oplus-feature.xml /my_product/etc/extension/com.oplus.oplus-feature.xml

# Google CN GMS Features
mount --bind $MODDIR/my_product/etc/permissions/oplus_google_cn_gms_features.xml /my_product/etc/permissions/oplus_google_cn_gms_features.xml
mount --bind $MODDIR/my_product/etc/permissions/oplus.feature.control_cn_gms.xml /my_product/etc/permissions/oplus.feature.control_cn_gms.xml
