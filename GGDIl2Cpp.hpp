
#pragma once
#include <stdint.h>
#include <stddef.h>

struct Il2CppDomain;
struct Il2CppThread;
struct Il2CppAssembly;
struct Il2CppImage;
struct Il2CppClass;
struct FieldInfo;
struct MethodInfo;
struct Il2CppObject;
struct Il2CppType;
struct Il2CppString;

struct Il2CppArray {
    Il2CppObject* klass;
    void* monitor;
    void* bounds;
    uintptr_t max_length;
    uintptr_t vector[1];
};

using il2cpp_domain_get_t = Il2CppDomain* (*)();
using il2cpp_thread_attach_t = Il2CppThread* (*)(Il2CppDomain*);
using il2cpp_domain_get_assemblies_t = const Il2CppAssembly** (*)(Il2CppDomain*, size_t*);
using il2cpp_assembly_get_image_t = const Il2CppImage* (*)(const Il2CppAssembly*);
using il2cpp_image_get_name_t = const char* (*)(const Il2CppImage*);
using il2cpp_class_from_name_t = Il2CppClass* (*)(const Il2CppImage*, const char*, const char*);
using il2cpp_class_get_field_from_name_t = FieldInfo* (*)(Il2CppClass*, const char*);
using il2cpp_field_static_get_value_t = void (*)(FieldInfo*, void*);
using il2cpp_field_get_value_t = void (*)(Il2CppObject*, FieldInfo*, void*);
using il2cpp_field_get_offset_t = size_t (*)(FieldInfo*);
using il2cpp_field_get_name_t = const char* (*)(FieldInfo*);
using il2cpp_field_get_type_t = const Il2CppType* (*)(FieldInfo*);
using il2cpp_type_get_name_t = const char* (*)(const Il2CppType*);
using il2cpp_object_get_class_t = Il2CppClass* (*)(Il2CppObject*);
using il2cpp_class_get_name_t = const char* (*)(Il2CppClass*);
using il2cpp_class_get_namespace_t = const char* (*)(Il2CppClass*);
using il2cpp_class_get_fields_t = FieldInfo* (*)(Il2CppClass*, void**);
using il2cpp_class_get_method_from_name_t = const MethodInfo* (*)(Il2CppClass*, const char*, int);
using il2cpp_runtime_invoke_t = Il2CppObject* (*)(const MethodInfo*, void*, void**, Il2CppObject**);
using il2cpp_string_length_t = int32_t (*)(Il2CppString*);
using il2cpp_string_chars_t = const uint16_t* (*)(Il2CppString*);

struct GGDIl2Cpp {
    void* handle = nullptr;
    il2cpp_domain_get_t domain_get = nullptr;
    il2cpp_thread_attach_t thread_attach = nullptr;
    il2cpp_domain_get_assemblies_t domain_get_assemblies = nullptr;
    il2cpp_assembly_get_image_t assembly_get_image = nullptr;
    il2cpp_image_get_name_t image_get_name = nullptr;
    il2cpp_class_from_name_t class_from_name = nullptr;
    il2cpp_class_get_field_from_name_t class_get_field_from_name = nullptr;
    il2cpp_field_static_get_value_t field_static_get_value = nullptr;
    il2cpp_field_get_value_t field_get_value = nullptr;
    il2cpp_field_get_offset_t field_get_offset = nullptr;
    il2cpp_field_get_name_t field_get_name = nullptr;
    il2cpp_field_get_type_t field_get_type = nullptr;
    il2cpp_type_get_name_t type_get_name = nullptr;
    il2cpp_object_get_class_t object_get_class = nullptr;
    il2cpp_class_get_name_t class_get_name = nullptr;
    il2cpp_class_get_namespace_t class_get_namespace = nullptr;
    il2cpp_class_get_fields_t class_get_fields = nullptr;
    il2cpp_class_get_method_from_name_t class_get_method_from_name = nullptr;
    il2cpp_runtime_invoke_t runtime_invoke = nullptr;
    il2cpp_string_length_t string_length = nullptr;
    il2cpp_string_chars_t string_chars = nullptr;

    bool resolve(const char* imagePath);
    bool attach();
    const Il2CppImage* findImage(const char* wanted);
    Il2CppClass* findClass(const char* name, const char* ns = nullptr);
    FieldInfo* findField(Il2CppClass* klass, const char* name);
    bool readStatic(FieldInfo* field, void* out);
    bool readField(Il2CppObject* object, FieldInfo* field, void* out);
    NSString* stringToNSString(Il2CppString* str);
};
