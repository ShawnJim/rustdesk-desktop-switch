# RustDesk Desktop Switch

在 Windows 11 宿主机上通过底层键盘钩子拦截 `Ctrl + Win + ← / →`，防止被全屏/前台的 RustDesk 转发到被控端，直接调用 Windows 11 原生虚拟桌面 COM 接口切换本地虚拟桌面。

## 原理

- `rustdesk_desktop_switch.ahk`：仅在 `RustDesk.exe` 处于前台时挂载 `WH_KEYBOARD_LL` 钩子并周期性置顶，自行维护修饰键状态，拦截 `Ctrl + Win + ← / →` 并吞掉方向键事件；离开 RustDesk 后自动卸载钩子，不影响宿主机正常打字。
- `rd_switch_worker.ahk`：独立后台工作进程，接收主脚本 `PostMessage` 通知后调用 Windows 11 原生 `IVirtualDesktopManagerInternal` COM 接口完成切换，零模拟按键，且避免切换过程阻塞键盘钩子线程。

## 环境要求

- **操作系统**：Windows 11 24H2 / 25H2（Build 26100 / 26200，COM IID `{53F5CA0B-158F-4124-900C-057158060B27}`）
- **运行环境**：[AutoHotkey v2.0+](https://www.autohotkey.com/)（官方签名版，兼容 Windows 智能应用控制）

## 使用方法

1. 安装 AutoHotkey v2（例如 `winget install AutoHotkey.AutoHotkey`）。
2. 双击运行 `rustdesk_desktop_switch.ahk`，在弹出的 UAC 窗口中点击 **「是」**（RustDesk 以提权/服务运行，脚本需要管理员权限才能抢占键盘钩子）。
3. 后台工作进程 `rd_switch_worker.ahk` 会自动拉起，右下角托盘出现绿色 **H** 图标即已生效。
4. 在 RustDesk 窗口中按 `Ctrl + Win + ← / →` 即可切换宿主机虚拟桌面。
5. 退出时右键托盘绿色 **H** 图标选择 **Exit**，会自动卸载钩子并关闭工作进程。

## 已知注意事项

- 切到宿主机桌面后，如果目标桌面没有已聚焦窗口，建议先点一下本机屏幕再打字，确保 RustDesk 正常失焦并释放键盘。
- 切回 RustDesk 所在桌面后，需先点一下 RustDesk 画面使窗口重新获得焦点，再使用快捷键切出。

## 发布新版本 (Release)

### 方式一：使用本地发版脚本

```powershell
.\scripts\release.ps1 -Version 0.1.0
```

脚本会自动：
1. 用 `AutoHotkey64.exe /Validate` 校验脚本语法；
2. 打包 `dist/rustdesk-desktop-switch-v<Version>.zip`；
3. 创建带注释的 Git Tag `v<Version>`；
4. 若已配置 `origin` 远程仓库，可通过 `-Push` 参数自动推送分支与标签，触发 GitHub Actions 自动发布 Release。

```powershell
.\scripts\release.ps1 -Version 0.2.0 -Push
```

### 方式二：GitHub Actions 自动发布

推送任意 `v*` 格式标签（如 `git push origin v0.1.0`），`.github/workflows/release.yml` 会自动打包 zip 并创建对应的 GitHub Release。
