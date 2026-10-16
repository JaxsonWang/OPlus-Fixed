# OPlus-Fixed

OPlus ColorOS Features Optimization Module.

## Features

- Feature unlock and system file overrides for OPlus devices (OPPO/OnePlus)
- Optional installation-time configuration via `customize.sh`
- Mount bindings for system file overrides
- Package-specific background protection for `com.mi.health`: adds it to Oplus Athena's `no_frozen` list after boot and applies the Android Doze exemption without disabling global freezer, O-Kill, or LMKD policies
- GKD startup compatibility: runs the installed GKD `files/sh/start.sh` and enables the accessibility component declared by the installed APK, including current GKD releases that use a renamed service component
- 可选原生 120Hz／165Hz 切换：在系统“刷新率设定”中选择默认高刷 120Hz 或极速高刷 165Hz，扩展应用高刷支持，保留智能切换及系统温控。

### Build

```shell
zip OPlus-Fixed-17.0.0.105.zip -9r META-INF system *.sh *.awk module.prop system.prop -x "*/.DS_Store"
```

## Installation

1. 下载 `OPlus-Fixed-17.0.0.105.zip`
2. Flash via KernelSU/Magisk Manager
3. Reboot device

安装时会依次询问四个可选项：小米健康后台保活、GKD 启动兼容、原生 120Hz／165Hz 切换和 Unlock CN GMS。按音量上键安装，按音量下键或等待 20 秒超时忽略。忽略小米健康或 GKD 后，对应功能不会由模块的开机服务和 action 手动入口执行；重新安装或更新模块时可以重新选择。

## 在系统设置中切换 120Hz／165Hz

安装时选择“原生 120Hz / 165Hz 切换”，重启后进入 **设置 → 显示与亮度 → 屏幕刷新率 → 高刷新率 → 刷新率设定**：

- **默认高刷 120Hz**：普通高刷档的默认、包名和 Activity 规则使用 120Hz。
- **极速高刷 165Hz**：独立极速高刷档的默认、包名和 Activity 规则使用 165Hz。
- **支持高刷新率的应用**：继续使用系统原生的应用级设置。

两个档位由系统即时切换，不需要重新刷模块或重启。智能切换及手动 60/90Hz 档保留原配置的档位值，不再统一推到 165Hz。模块版本仍为 `17.0.0.105`，适配本次检查的 `PLK110_17.0.0.105(CN01)` 系统。

### 实现与生效条件

安装器检查设备原生支持 165Hz，并在选择此功能时向模块的 `system.prop` 写入：

```properties
persist.performance.rapid.refresh_rate.level=165
persist.performance.rapid.refresh_rate.is_perf_mode=true
```

第一项启用系统设置已有的 120Hz／165Hz 菜单；第二项让原生应用列表提供极速高刷选择，不局限于预置的少数应用。由 Root 管理器加载模块属性，不直接写入 persist 属性的持久化存储，不修改设置 APK。

系统设置在选择 120Hz 时使用 `mode 3`，选择 165Hz 时使用 `mode 8`。两者分别读取 `rateId` 的第四项、第五项；第五项填入刷新率 ID `7`（165Hz），不是 ID `8`（185Hz）。因此默认和应用规则保留前三项，并将最后两项设为 `3-7`，例如：

```xml
<config defaultRateId="1-1-2-3-7" defaultMaxRate="120" maxrefreshsettings="3" />
<item package="example.app" rateId="1-1-2-3-7" />
```

`maxrefreshsettings` 保持 `3`，避免普通高刷档和锁屏被统一强制成 165Hz。处理应用规则中的 View／窗口降刷覆盖及 `appreqfirst`，保留用户的应用独立设置、相机、录屏、亮度和温控等专项规则。系统未列出的应用可以使用默认策略，并可在原生应用列表中单独选择。

每次开机在 `post-fs-data.sh` 阶段，从手机当前配置生成模块副本，通过 bind mount 覆盖：

```text
/my_product/etc/refresh_rate_config.xml
/data/system/refresh_rate_config.xml
```

数据副本仅在原文件存在时处理。系统按版本选择两份配置，因此两边都转换并保留版本号；不写入原文件，不常驻轮询。若系统在本次开机期间下发并加载新配置，需重启重新应用。

以下文件保持原样：

- `sys_dynamic_frame_config.xml`：本机动画解析器只接受 90 或 120，不能写入 165；部分系统动画仍使用原有 120fps 规则。
- `oplus_vrr_config.json`：保留亮度、面板时序、游戏 TE 和空闲降刷策略。

**选择 165Hz 不等于所有应用恒定渲染 165fps。** 应用自身锁帧、用户独立设置、游戏、省电、相机、温控及 VRR 空闲策略仍会影响实际帧率。165Hz 可能增加耗电和发热。

### 验证与恢复

开机日志：`/data/adb/modules/oplus_fixed/refresh-rate-165.log`。

```shell
adb shell settings get secure choice_mode_rate
adb shell dumpsys oplusscreenmode
adb shell dumpsys display
```

选择 120Hz 时，`choice_mode_rate` 应为 `120`，`mCurrentPickMode` 为 `3`；选择 165Hz 时分别为 `165`、`8`。配置默认数组应以 `3, 7` 结尾。结合当前应用的 `mCurrentPickRate` 与 `mActiveSfDisplayMode` 验证实际显示刷新率，应用渲染帧率需另外测量。

已在 `PLK110_17.0.0.105(CN01)` 上重启验证：原生下拉菜单显示两个档位，通过菜单切换后，计算器的 `mActiveSfDisplayMode` 分别为 `120.00001Hz` 和 `165Hz`，应用高刷列表正常打开。此结果验证显示模式切换，不代表所有应用都能渲染同等帧率。

停用或卸载模块后重启，恢复原生配置与菜单属性；保留用户通过系统设置作出的选择，不清空应用独立偏好。action 按钮不负责切换刷新率档位。

本地回归检查：`python3 -m unittest discover -s tests -v`。

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
