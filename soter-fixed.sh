#!/system/bin/sh

stop vendor.soter
sleep 1
pm clear com.tencent.soter.soterserver
start vendor.soter
sleep 1
getprop init.svc.vendor.soter
echo "SOTER KEY 伪造成功"
