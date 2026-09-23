# OPlus-Fixed

OPlus ColorOS Features Optimization Module.

## Features

- Feature unlock and system file overrides for OPlus devices (OPPO/OnePlus)
- Optional installation-time configuration via `customize.sh`
- Mount bindings for system file overrides
- Package-specific background protection for `com.mi.health`: adds it to Oplus Athena's `no_frozen` list after boot and applies the Android Doze exemption without disabling global freezer, O-Kill, or LMKD policies
- GKD startup compatibility: runs the installed GKD `files/sh/start.sh` and enables the accessibility component declared by the installed APK, including current GKD releases that use a renamed service component

### Build

```shell
zip OPlus-Fixed.zip -9r * -x "LICENSE" "README.md" "*/.DS_Store" "demo.png" "AGENTS.md" "OPlus-Fixed-*.zip"
```

## Installation

1. Download OPlus-Fixed.zip
2. Flash via KernelSU/Magisk Manager
3. Reboot device

安装时会依次询问三个可选项：小米健康后台保活、GKD 启动兼容和 Unlock CN GMS。每个选项都显示“请使用音量按键选择”：按音量上键安装，按音量下键或等待超时忽略。忽略小米健康或 GKD 后，对应功能不会由模块的开机服务和 action 手动入口执行；重新安装或更新模块时可以重新选择。

## `com.mi.health` background protection

小米健康保活的逻辑是按包名处理，不修改整个系统的全局省电策略：

1. 开机后等待系统服务稳定，确认 `com.mi.health` 和 Oplus Athena 都已安装，并检查现有 `no_frozen` 格式可安全读取。
2. 第一次成功应用前，将原始 `no_frozen` 值和 Doze 白名单状态保存到当前模块目录的 `.state/health-background/baseline`。
3. 只把 `com.mi.health` 追加到 `settings --user 0` 的 secure `no_frozen` 列表，并通过 `cmd deviceidle whitelist +com.mi.health` 增加 Android Doze 豁免；已有条目不会重复写入。
4. 每次写入后读取回执并校验，开机流程会在延迟后再执行一次；之后后台每 60 秒重新校验并补回被 Athena 后续刷新掉的条目。
5. 卸载时只移除本模块加入的条目，保留用户或其他模块后来加入的配置；如果安装前已经存在对应条目，则不删除。

这套逻辑不关闭全局 freezer、O-Kill 或 LMKD，也不保证在系统内存紧张时进程绝对不会被回收。它主要针对 Athena 的冻结和 Android Doze 休眠；最终是否长期运行还取决于系统版本、电池策略和应用自身状态。状态和日志都在当前模块目录：运行日志是 `/data/adb/modules/oplus_fixed/health-background.log`，运行状态和基线位于 `/data/adb/modules/oplus_fixed/.state/health-background/`。卸载回滚会创建停用标记，后台 watcher 检测到后退出。

旧版本曾经使用 `/data/adb/oplus_fixed/`，升级后遗留的旧目录不会被脚本自动删除；新版本不会再向该目录写入运行日志或运行状态。

The script validates the package, Athena, the existing list format, and each write. A lock prevents overlapping runs. It runs twice after boot because Athena can finish loading its default configuration after `sys.boot_completed`.

To inspect the current state or apply the policy manually, run:

```shell
su -c /data/adb/modules/oplus_fixed/health-background-fix.sh --status
su -c /data/adb/modules/oplus_fixed/health-background-fix.sh --apply
```

To restore the original secure `no_frozen` value from the backup, run:

```shell
su -c /data/adb/modules/oplus_fixed/health-background-fix.sh --restore
```

The module includes `uninstall.sh`, which performs the same package-specific rollback before the module is removed.

## GKD startup compatibility

The module does not hardcode a Java service class. It discovers the accessibility service from the installed `li.songe.gkd` package, preserves the existing accessibility service list, and restores it on uninstall only when the module added the GKD component. GKD's own `start.sh` remains the source of its grants and `ExposeService` startup. Runtime status is written to `/data/adb/modules/oplus_fixed/gkd-start.log`, while the accessibility baseline stays under `/data/adb/modules/oplus_fixed/.state/gkd` for rollback.

## Support

- Module documentation: [AGENTS.md](AGENTS.md)
