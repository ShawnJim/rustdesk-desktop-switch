#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
Persistent

; 独立工作进程：只负责调用 Windows 11 COM 接口切换虚拟桌面（不做任何焦点处理）
DetectHiddenWindows(true)
gui1 := Gui(, "RDSwitchWorker_v5")
gui1.Show("Hide")
OnMessage(0x8001, OnSwitch)

OnSwitch(wParam, lParam, msg, hwnd) {
    SetTimer(() => SwitchDesktopNative(wParam), -1)
    return 1
}

SwitchDesktopNative(direction) {
    try {
        shell := ComObject("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{6D5140C1-7436-11CE-8034-00AA006009FA}")
        mgr := ComObjQuery(shell, "{C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B}", "{53F5CA0B-158F-4124-900C-057158060B27}")
        cur := 0
        ComCall(6, mgr, "Ptr*", &cur, "Int")
        target := 0
        hrAdj := ComCall(8, mgr, "Ptr", cur, "Int", direction, "Ptr*", &target, "Int")
        ObjRelease(cur)
        if (hrAdj != 0 || !target)
            return
        ComCall(9, mgr, "Ptr", target, "Int")
        ObjRelease(target)
    }
}
