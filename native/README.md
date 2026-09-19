# Windows mouse passthrough

`WindowsMousePassthrough` is an abstract GDExtension class with two static methods:

- `set_passthrough(hwnd: int, enabled: bool) -> bool`
- `is_passthrough(hwnd: int) -> bool`

Pass `DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, window.get_window_id())` after a native Window exists. Only handles belonging to the current process are accepted. Call from the Godot main thread. A false setter result means the handle was invalid or Windows rejected the operation.

Godot 4.5.2's `Window.mouse_passthrough` returns `HTTRANSPARENT`, which only forwards hit testing within the same thread. A layered window with `WS_EX_TRANSPARENT` passes mouse events to applications below it. The extension preserves unrelated extended styles, adds full-alpha layering once, and toggles only `WS_EX_TRANSPARENT` afterward. Godot continues to render per-pixel transparency through DWM; no clipping region or color key is applied.

Build with `powershell -File tools/build_native.ps1` using Visual Studio 2022 C++ x64 tools. The release DLL uses the static MSVC runtime (`/MT`), so no VC redistributable is needed. Godot exports the library through `windows_mouse_passthrough.gdextension`; include that DLL beside the exported executable in the portable archive. Import the project before running `godot --path . --script native/test_native.gd` with the Windows display server.

## Third-party source

`vendor/gdextension_interface.h` is copied unchanged from [Godot 4.5.2](https://github.com/godotengine/godot/blob/4.5.2-stable/core/extension/gdextension_interface.h). Its MIT license and copyright are retained in the file. There is no godot-cpp dependency.

The behavior follows Microsoft's [Layered Windows documentation](https://learn.microsoft.com/en-us/windows/win32/winmsg/window-features#layered-windows).
