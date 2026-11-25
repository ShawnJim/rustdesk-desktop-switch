# Changelog

All notable changes to this project will be documented in this file.

## [v0.1.0] - 2026-11-25

### Added
- `rustdesk_desktop_switch.ahk`: 仅在 RustDesk 前台时挂载并置顶 `WH_KEYBOARD_LL` 钩子，自维护修饰键状态，拦截 `Ctrl + Win + ← / →`；离开 RustDesk 后自动卸载钩子。
- `rd_switch_worker.ahk`: 独立后台工作进程，通过 Windows 11 24H2/25H2 原生 `IVirtualDesktopManagerInternal` COM 接口执行虚拟桌面切换，避免阻塞键盘钩子线程。
- 添加本地发版脚本 `scripts/release.ps1` 与 GitHub Actions 自动 Release 工作流 `.github/workflows/release.yml`。
