#!/bin/sh

echo "开始运行"

if [ -f /data/user/0/cn.gov.pbc.dcep/envc.push ]; then
  echo "检测到数字人民币! 开始解决数字人民币Root检测"
  #防之前刷过模块先预先取消掉属性
  chattr -i /data/user/0/cn.gov.pbc.dcep/envc.push
  #强制设置文件内容为安全
  echo "r=0" > /data/user/0/cn.gov.pbc.dce/envc.push
  #将文件设置为不能被软件轻易更改
  chattr +i /data/user/0/cn.gov.pbc.dce/envc.push
  echo "成功解决数字人民币Root检测!"
fi

logcat -c >/dev/null 2>&1
logcat --clear >/dev/null 2>&1
dmesg -c >/dev/null 2>&1
echo "系统日志清理完成"

rm -rf /data/local/tmp/shizuku/
rm -rf /data/local/tmp/shizuku_starter
rm -f /data/local/tmp/shizuku/
rm -f /data/local/tmp/shizuku_starter
echo "清理 Shizuku 残留"

# 清除阻止 GMS 持续持有 WakeLock
# settings put secure google_restric_info 0
