#!/system/bin/sh
MODDIR=${0%/*}

# mount -o ro,bind $MODDIR/my_product/etc/extension/com.oplus.app-features.xml /my_product/etc/extension/com.oplus.app-features.xml
# mount -o ro,bind $MODDIR/my_product/etc/extension/com.oplus.oplus-feature.xml /my_product/etc/extension/com.oplus.oplus-feature.xml
# mount -o ro,bind $MODDIR/my_product/etc/permissions/oplus.product.feature_multimedia_unique.xml /my_product/etc/permissions/oplus.product.feature_multimedia_unique.xml
mount -o ro,bind $MODDIR/my_bigball/etc/permissions/oplus_google_cn_gms_features.xml /my_bigball/etc/permissions/oplus_google_cn_gms_features.xml
mount -o ro,bind $MODDIR/my_bigball/etc/permissions/oplus.feature.control_cn_gms.xml /my_bigball/etc/permissions/oplus.feature.control_cn_gms.xml
