#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; 自动请求管理员权限
if !A_IsAdmin {
    try Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
    ExitApp()
}

; ---------- 启动独立的桌面切换工作进程 ----------
DetectHiddenWindows(true)
workerScript := A_ScriptDir "\rd_switch_worker.ahk"
Run('"' A_AhkPath '" /restart "' workerScript '"')
global workerHwnd := WinWait("RDSwitchWorker_v5 ahk_class AutoHotkeyGUI", , 5)

; ---------- 自维护修饰键状态 ----------
global lCtrl := false, rCtrl := false, lWin := false, rWin := false
global swallowUp := Map()
global rdActive := false

; ---------- 自建 WH_KEYBOARD_LL 钩子：回调里只做最少的事，绝不阻塞 ----------
global hookCb := CallbackCreate(LLKeyboardProc, "Fast", 3)
global hHook := 0

InstallHook() {
    global hHook, hookCb
    old := hHook
    hHook := DllCall("SetWindowsHookEx", "Int", 13, "Ptr", hookCb
        , "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr"), "UInt", 0, "Ptr")
    if old
        DllCall("UnhookWindowsHookEx", "Ptr", old)
}

LLKeyboardProc(nCode, wParam, lParam) {
    global lCtrl, rCtrl, lWin, rWin, swallowUp, rdActive, workerHwnd
    if (nCode >= 0) {
        vk := NumGet(lParam, 0, "UInt")
        injected := NumGet(lParam, 8, "UInt") & 0x10
        isDown := (wParam = 0x100 || wParam = 0x104)

        if !injected {
            switch vk {
                case 0xA2, 0x11: lCtrl := isDown
                case 0xA3: rCtrl := isDown
                case 0x5B: lWin := isDown
                case 0x5C: rWin := isDown
            }
        }

        if (!isDown && swallowUp.Has(vk)) {
            swallowUp.Delete(vk)
            return 1
        }

        if (isDown && !injected && rdActive && (vk = 0x25 || vk = 0x27)
            && (lCtrl || rCtrl) && (lWin || rWin)) {
            swallowUp[vk] := true
            ; 只投递消息给工作进程（非阻塞），立即返回
            DllCall("PostMessage", "Ptr", workerHwnd, "UInt", 0x8001, "Ptr", (vk = 0x25) ? 3 : 4, "Ptr", 0)
            return 1
        }
    }
    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam, "Ptr")
}

; ---------- 前台检测：仅在 RustDesk 前台时挂钩，离开就卸载 ----------
CheckForeground() {
    global rdActive, hHook, lCtrl, rCtrl, lWin, rWin
    rdActive := WinActive("ahk_exe rustdesk.exe") ? true : false
    if rdActive {
        if !(lCtrl || rCtrl || lWin || rWin)
            InstallHook()   ; 不断把钩子插回链首，压过 RustDesk
    } else if hHook {
        ; 离开 RustDesk 后彻底卸载钩子，本机键盘完全不经过脚本
        DllCall("UnhookWindowsHookEx", "Ptr", hHook)
        hHook := 0
        lCtrl := rCtrl := lWin := rWin := false
        swallowUp.Clear()
    }
}

SetTimer(CheckForeground, 250)

OnExit(Cleanup)
Cleanup(*) {
    global hHook, workerHwnd
    if hHook
        DllCall("UnhookWindowsHookEx", "Ptr", hHook)
    try WinClose("ahk_id " workerHwnd)
}
