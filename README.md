# OPlus-Fixed

OPlus ColorOS Features Optimization Module with WebUI support for KernelSU.

## Features

- Root detection bypass for OPlus devices (OPPO/OnePlus)
- System property spoofing to hide root status
- Digital currency (DCEP) app detection bypass
- SOTER key service fix
- **Modern WebUI interface** (KernelSU only)
- Log cleaning and trace removal
- Mount bindings for system file overrides

## WebUI (KernelSU)

The module includes a modern WebUI interface accessible via KernelSU Manager:
- Device information display
- One-click repair execution
- Real-time execution logs
- Copy output to clipboard

See [WEBUI.md](WEBUI.md) for detailed usage instructions.

### Build

```shell
zip OPlus-Fixed.zip -9r * -x "LICENSE" "README.md" "*/.DS_Store" "demo.png"
```

## Installation

1. Download OPlus-Fixed.zip
2. Flash via KernelSU/Magisk Manager
3. Reboot device
4. (Optional) Open module WebUI in KernelSU Manager

## Manual Execution

```bash
adb shell su -c "sh /data/adb/modules/oplus_fixed/action.sh"
```

## Support

- Module documentation: [AGENTS.md](AGENTS.md)
- WebUI guide: [WEBUI.md](WEBUI.md)
