#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "vendor/gdextension_interface.h"

static GDExtensionClassLibraryPtr library;
static GDExtensionInterfaceGetProcAddress get_proc;
static GDExtensionInterfaceStringNameNewWithUtf8Chars make_name;
static GDExtensionPtrDestructor destroy_name;
static GDExtensionVariantFromTypeConstructorFunc from_bool;
static GDExtensionTypeFromVariantConstructorFunc to_int, to_bool;
static GDExtensionInterfaceVariantGetType variant_type;

// StringName is one pointer in Godot's x64 ABI. Names are copied by ClassDB.
struct Name {
    void *value;
    Name(const char *text) { make_name(&value, text); }
    ~Name() { destroy_name(&value); }
};

static HWND own_window(int64_t handle) {
    HWND window = reinterpret_cast<HWND>(static_cast<intptr_t>(handle));
    DWORD process = 0;
    if (!IsWindow(window) || !GetWindowThreadProcessId(window, &process) || process != GetCurrentProcessId()) return nullptr;
    return window;
}

static bool is_passthrough(int64_t handle) {
    HWND window = own_window(handle);
    return window && (GetWindowLongPtrW(window, GWL_EXSTYLE) & WS_EX_TRANSPARENT) != 0;
}

static bool set_passthrough(int64_t handle, bool enabled) {
    HWND window = own_window(handle);
    if (!window) return false;
    LONG_PTR before = GetWindowLongPtrW(window, GWL_EXSTYLE);
    LONG_PTR after = enabled ? before | WS_EX_TRANSPARENT | WS_EX_LAYERED : before & ~WS_EX_TRANSPARENT;
    if (before == after) return true;
    SetLastError(0);
    if (!SetWindowLongPtrW(window, GWL_EXSTYLE, after) && GetLastError()) return false;
    // Layering is kept when disabling passthrough to avoid resetting the render surface.
    // Full constant alpha preserves Godot's DWM per-pixel transparency.
    if (enabled && !(before & WS_EX_LAYERED) && !SetLayeredWindowAttributes(window, 0, 255, LWA_ALPHA)) {
        SetWindowLongPtrW(window, GWL_EXSTYLE, before);
        return false;
    }
    return is_passthrough(handle) == enabled;
}

static void ptrcall(void *method, GDExtensionClassInstancePtr, const GDExtensionConstTypePtr *args, GDExtensionTypePtr result) {
    int64_t handle = *static_cast<const int64_t *>(args[0]);
    *static_cast<GDExtensionBool *>(result) = method ? set_passthrough(handle, *static_cast<const GDExtensionBool *>(args[1]) != 0) : is_passthrough(handle);
}

static void call(void *method, GDExtensionClassInstancePtr, const GDExtensionConstVariantPtr *args, GDExtensionInt count, GDExtensionVariantPtr result, GDExtensionCallError *error) {
    GDExtensionBool value = false;
    int required = method ? 2 : 1;
    error->error = GDEXTENSION_CALL_OK;
    if (count != required) {
        error->error = count < required ? GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS : GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS;
        error->expected = required;
    } else {
        for (int i = 0; i < required; ++i) {
            auto expected = i == 0 ? GDEXTENSION_VARIANT_TYPE_INT : GDEXTENSION_VARIANT_TYPE_BOOL;
            if (variant_type(args[i]) != expected) {
                error->error = GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT;
                error->argument = i;
                error->expected = expected;
                from_bool(result, &value);
                return;
            }
        }
        int64_t handle;
        GDExtensionBool enabled = false;
        to_int(&handle, const_cast<void *>(args[0]));
        if (method) to_bool(&enabled, const_cast<void *>(args[1]));
        value = method ? set_passthrough(handle, enabled != 0) : is_passthrough(handle);
    }
    from_bool(result, &value);
}

static void initialize(void *, GDExtensionInitializationLevel level) {
    if (level != GDEXTENSION_INITIALIZATION_SCENE) return;
    Name name("WindowsMousePassthrough"), parent("Object"), empty(""), handle("hwnd"), enabled("enabled");
    void *hint_string;
    reinterpret_cast<GDExtensionInterfaceStringNewWithUtf8Chars>(get_proc("string_new_with_utf8_chars"))(&hint_string, "");
    GDExtensionClassCreationInfo4 info = {};
    info.is_abstract = true;
    info.is_exposed = true;
    reinterpret_cast<GDExtensionInterfaceClassdbRegisterExtensionClass4>(get_proc("classdb_register_extension_class4"))(library, &name.value, &parent.value, &info);
    GDExtensionPropertyInfo ret = {GDEXTENSION_VARIANT_TYPE_BOOL, &empty.value, &empty.value, 0, &hint_string, 6};
    GDExtensionPropertyInfo args[] = {
        {GDEXTENSION_VARIANT_TYPE_INT, &handle.value, &empty.value, 0, &hint_string, 6},
        {GDEXTENSION_VARIANT_TYPE_BOOL, &enabled.value, &empty.value, 0, &hint_string, 6}
    };
    GDExtensionClassMethodArgumentMetadata metadata[] = {GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT64, GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE};
    for (int i = 0; i < 2; ++i) {
        Name method(i ? "set_passthrough" : "is_passthrough");
        GDExtensionClassMethodInfo binding = {};
        binding.name = &method.value;
        binding.method_userdata = reinterpret_cast<void *>(static_cast<intptr_t>(i));
        binding.call_func = call;
        binding.ptrcall_func = ptrcall;
        binding.method_flags = GDEXTENSION_METHOD_FLAG_NORMAL | GDEXTENSION_METHOD_FLAG_STATIC;
        binding.has_return_value = true;
        binding.return_value_info = &ret;
        binding.argument_count = i ? 2 : 1;
        binding.arguments_info = args;
        binding.arguments_metadata = metadata;
        reinterpret_cast<GDExtensionInterfaceClassdbRegisterExtensionClassMethod>(get_proc("classdb_register_extension_class_method"))(library, &name.value, &binding);
    }
    reinterpret_cast<GDExtensionInterfaceVariantGetPtrDestructor>(get_proc("variant_get_ptr_destructor"))(GDEXTENSION_VARIANT_TYPE_STRING)(&hint_string);
}

static void deinitialize(void *, GDExtensionInitializationLevel level) {
    if (level != GDEXTENSION_INITIALIZATION_SCENE) return;
    Name name("WindowsMousePassthrough");
    reinterpret_cast<GDExtensionInterfaceClassdbUnregisterExtensionClass>(get_proc("classdb_unregister_extension_class"))(library, &name.value);
}

extern "C" __declspec(dllexport) GDExtensionBool windows_mouse_passthrough_init(GDExtensionInterfaceGetProcAddress proc, GDExtensionClassLibraryPtr lib, GDExtensionInitialization *init) {
    get_proc = proc;
    library = lib;
    make_name = reinterpret_cast<GDExtensionInterfaceStringNameNewWithUtf8Chars>(proc("string_name_new_with_utf8_chars"));
    destroy_name = reinterpret_cast<GDExtensionInterfaceVariantGetPtrDestructor>(proc("variant_get_ptr_destructor"))(GDEXTENSION_VARIANT_TYPE_STRING_NAME);
    from_bool = reinterpret_cast<GDExtensionInterfaceGetVariantFromTypeConstructor>(proc("get_variant_from_type_constructor"))(GDEXTENSION_VARIANT_TYPE_BOOL);
    auto to_type = reinterpret_cast<GDExtensionInterfaceGetVariantToTypeConstructor>(proc("get_variant_to_type_constructor"));
    to_int = to_type(GDEXTENSION_VARIANT_TYPE_INT);
    to_bool = to_type(GDEXTENSION_VARIANT_TYPE_BOOL);
    variant_type = reinterpret_cast<GDExtensionInterfaceVariantGetType>(proc("variant_get_type"));
    init->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
    init->userdata = nullptr;
    init->initialize = initialize;
    init->deinitialize = deinitialize;
    return true;
}

