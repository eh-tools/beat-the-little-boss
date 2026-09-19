# Use a small native extension for Windows mouse passthrough

Status: accepted, 2026-09-14

Godot 4.5.2 `Window.mouse_passthrough` uses the `HTTRANSPARENT` hit-test result. Actual Windows testing showed transparent margins still swallowed clicks intended for another process. Godot's polygon passthrough API clips rendering on Windows, including effects outside the polygon.

Use a minimal GDExtension exposing `WindowsMousePassthrough.set_passthrough(hwnd, enabled)`. It sets the Win32 `WS_EX_TRANSPARENT` / `WS_EX_LAYERED` flags while preserving unrelated flags. The main window toggles passthrough based on the visible sprite pixels; the separate speech window always passes input through. Handles must belong to the current process.

The tradeoff is one small Windows x64 DLL beside the executable and a C++ toolchain for rebuilding that DLL. No extra runtime installation or godot-cpp dependency is needed. Actual clicks reached an independent Python/Tk application through both a transparent main-window margin and the visible speech bubble, while visual transparency remained intact.

References: [Godot DisplayServer](https://docs.godotengine.org/en/4.5/classes/class_displayserver.html), [Microsoft layered windows](https://learn.microsoft.com/en-us/windows/win32/winmsg/window-features#layered-windows).
