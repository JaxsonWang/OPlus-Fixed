while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 3
done

#开机执行，更新系统后自动禁用
avbctl disable-verity --force
avbctl disable-verification --force
