#import "GGDCore.hpp"
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#include <unistd.h>
#include <string.h>

static void* resolveAny(void* h, const char* a) {
    return h ? dlsym(h, a) : nullptr;
}

bool GGDIl2Cpp::resolve(const char* imagePath) {
    handle = nullptr;
    // 优先从当前进程已经加载的 Mach-O 中寻找 UnityFramework。
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; ++i) {
        const char* imageName = _dyld_get_image_name(i);
        if (!imageName) continue;
        if (strstr(imageName, "UnityFramework.framework/UnityFramework") ||
            strstr(imageName, "/UnityFramework")) {
            handle = dlopen(imageName, RTLD_LAZY | RTLD_NOLOAD);
            if (handle) break;
        }
    }

    // 兜底尝试。
    if (!handle && imagePath) {
        handle = dlopen(imagePath, RTLD_LAZY | RTLD_NOLOAD);
    }

    if (!handle) return false;

#define R(member, symbol) member = (decltype(member))resolveAny(handle, symbol)
    R(domain_get, "il2cpp_domain_get");
    R(thread_attach, "il2cpp_thread_attach");
    R(domain_get_assemblies, "il2cpp_domain_get_assemblies");
    R(assembly_get_image, "il2cpp_assembly_get_image");
    R(image_get_name, "il2cpp_image_get_name");
    R(class_from_name, "il2cpp_class_from_name");
    R(class_get_field_from_name, "il2cpp_class_get_field_from_name");
    R(field_static_get_value, "il2cpp_field_static_get_value");
    R(field_get_value, "il2cpp_field_get_value");
    R(field_get_offset, "il2cpp_field_get_offset");
    R(field_get_name, "il2cpp_field_get_name");
    R(field_get_type, "il2cpp_field_get_type");
    R(type_get_name, "il2cpp_type_get_name");
    R(object_get_class, "il2cpp_object_get_class");
    R(class_get_name, "il2cpp_class_get_name");
    R(class_get_namespace, "il2cpp_class_get_namespace");
    R(class_get_fields, "il2cpp_class_get_fields");
    R(class_get_method_from_name, "il2cpp_class_get_method_from_name");
    R(runtime_invoke, "il2cpp_runtime_invoke");
    R(string_length, "il2cpp_string_length");
    R(string_chars, "il2cpp_string_chars");
#undef R

    return domain_get && thread_attach && domain_get_assemblies &&
           assembly_get_image && class_from_name && class_get_field_from_name &&
           field_static_get_value;
}

bool GGDIl2Cpp::attach() {
    return domain_get && thread_attach && thread_attach(domain_get());
}

const Il2CppImage* GGDIl2Cpp::findImage(const char* wanted) {
    if (!domain_get_assemblies || !assembly_get_image) return nullptr;
    size_t count = 0;
    auto list = domain_get_assemblies(domain_get(), &count);
    for (size_t i = 0; i < count; ++i) {
        const Il2CppImage* img = assembly_get_image(list[i]);
        if (!img) continue;
        if (!wanted || !image_get_name) return img;
        const char* n = image_get_name(img);
        if (n && strstr(n, wanted)) return img;
    }
    return nullptr;
}

Il2CppClass* GGDIl2Cpp::findClass(const char* name, const char* ns) {
    if (!class_from_name || !name) return nullptr;

    size_t count = 0;
    auto list = domain_get_assemblies(domain_get(), &count);
    const char* namespaces[] = {
    "",
    "Goose",
    "Goose.Ctls",
    "Assembly-CSharp",
    nullptr
};

for (size_t i = 0; i < count; ++i) {
    const Il2CppImage* img = assembly_get_image(list[i]);
    if (!img) continue;

    // 如果调用者明确指定 namespace，先精确查找。
    if (ns && *ns) {
        if (auto c = class_from_name(img, ns, name))
            return c;
        continue;
    }
    // 未指定 namespace 时，依次搜索常见 namespace。
    for (int n = 0; namespaces[n]; ++n) {
        if (auto c = class_from_name(img, namespaces[n], name))
            return c;
    }
}

    return nullptr;
}

FieldInfo* GGDIl2Cpp::findField(Il2CppClass* klass, const char* name) {
    return (klass && class_get_field_from_name) ?
        class_get_field_from_name(klass, name) : nullptr;
}

bool GGDIl2Cpp::readStatic(FieldInfo* field, void* out) {
    if (!field || !out || !field_static_get_value) return false;
    field_static_get_value(field, out);
    return true;
}

bool GGDIl2Cpp::readField(Il2CppObject* object, FieldInfo* field, void* out) {
    if (!object || !field || !out || !field_get_value) return false;
    field_get_value(object, field, out);
    return true;
}

NSString* GGDIl2Cpp::stringToNSString(Il2CppString* str) {
    if (!str || !string_length || !string_chars) return nil;
    int32_t len = string_length(str);
    if (len < 0 || len > 2048) return nil;
    const uint16_t* chars = string_chars(str);
    if (!chars) return nil;
    return [[NSString alloc] initWithCharacters:(const unichar*)chars length:(NSUInteger)len];
}

static FieldInfo* firstField(GGDIl2Cpp& api, Il2CppClass* c, const char* const* names) {
    if (!c) return nullptr;
    for (int i=0; names[i]; ++i) {
        if (auto f = api.findField(c, names[i])) return f;
    }
    return nullptr;
}

static NSString* readStringCandidate(GGDIl2Cpp& api, Il2CppObject* obj, Il2CppClass* c,
                                     const char* const* names) {
    FieldInfo* f = firstField(api, c, names);
    if (!f) return nil;
    Il2CppString* s = nullptr;
    if (!api.readField(obj, f, &s)) return nil;
    return api.stringToNSString(s);
}

static bool readIntCandidate(GGDIl2Cpp& api, Il2CppObject* obj, Il2CppClass* c,
                             const char* const* names, int32_t& out) {
    FieldInfo* f = firstField(api, c, names);
    if (!f) return false;
    out = 0;
    if (!api.readField(obj, f, &out)) return false;
    return true;
}

static Il2CppObject* readObjectField(GGDIl2Cpp& api, Il2CppObject* obj, Il2CppClass* c,
                                     const char* const* names) {
    FieldInfo* f = firstField(api, c, names);
    if (!f) return nullptr;
    Il2CppObject* v = nullptr;
    api.readField(obj, f, &v);
    return v;
}

@implementation GGDPlayerSnapshot @end

@interface GGDCore () {
    GGDIl2Cpp _api;
    Il2CppClass* _gooseGame;
    FieldInfo* _playersField;
    Il2CppClass* _playerClass;
    Il2CppClass* _cameraClass;
    const MethodInfo* _cameraMain;
    const MethodInfo* _componentTransform;
    const MethodInfo* _cameraWorldToScreen;
    NSMutableArray* _snapshots;
    NSString* _status;
    BOOL _started;
    BOOL _ready;
}
@end

@implementation GGDCore

+ (instancetype)shared {
    static GGDCore* s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [GGDCore new]; });
    return s;
}

- (instancetype)init {
    if ((self=[super init])) {
        _snapshots=[NSMutableArray array];
        _status=@"等待 UnityFramework";
    }
    return self;
}

- (BOOL)il2cppReady { return _api.handle != nullptr; }
- (BOOL)gameReady { return _ready; }
- (NSUInteger)playerCount { return _snapshots.count; }
- (NSArray*)snapshots { return [_snapshots copy]; }
- (NSString*)statusLine { return _status ?: @""; }

- (void)start {
    if (_started) return;
    _started=YES;

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0), ^{
        for (int i=0;i<100;i++) {
            bool ok = _api.resolve(nullptr);
            if (ok && _api.attach()) break;
            usleep(200000);
        }
        dispatch_async(dispatch_get_main_queue(), ^{ [self tick]; });
    });
}

- (void)tick {
    if (!_api.handle) return;
    _api.attach();

    if (!_gooseGame) _gooseGame=_api.findClass("GooseGame");
    if (!_gooseGame) {
        _status=@"IL2CPP 已连接 · GooseGame 未找到";
        return;
    }

    if (!_playersField) {
        const char* names[]={"players","Players","m_players","playerList","PlayerList",nullptr};
        _playersField=firstField(_api,_gooseGame,names);
    }
    if (!_playersField) {
        _status=@"GooseGame 已找到 · players 字段未找到";
        return;
    }

    Il2CppObject* list=nullptr;
    if (!_api.readStatic(_playersField,&list) || !list) {
        _status=@"players 已找到 · 当前尚未初始化";
        return;
    }

    _ready=YES;

    Il2CppClass* listClass=_api.object_get_class ? _api.object_get_class(list) : nullptr;
    static const char* itemNames[]={"_items","items",nullptr};
    static const char* sizeNames[]={"_size","size",nullptr};
    FieldInfo* itemsField=firstField(_api,listClass,itemNames);
    FieldInfo* sizeField=firstField(_api,listClass,sizeNames);

    Il2CppArray* items=nullptr;
    int32_t size=0;
    if (!itemsField || !sizeField ||
        !_api.readField(list,itemsField,(void*)&items) ||
        !_api.readField(list,sizeField,&size) || !items) {
        _status=@"players 已获取 · List<T> 读取失败";
        return;
    }

    if (size<0) size=0;
    if (size>64) size=64;

    [_snapshots removeAllObjects];

    for (int32_t i=0;i<size;i++) {
        Il2CppObject* player=((Il2CppObject**)items->vector)[i];
        if (!player) continue;

        if (!_playerClass && _api.object_get_class)
            _playerClass=_api.object_get_class(player);

        Il2CppClass* pc=_api.object_get_class ? _api.object_get_class(player) : _playerClass;
        if (!pc) continue;

        static const char* nameFields[]={
            "Name","name","PlayerName","playerName","Nickname","nickname",
            "NickName","nickName","Uid","uid","UID",nullptr
        };
        static const char* roleFields[]={
            "RoleName","roleName","Role","role","CurrentRole","currentRole",
            "RoleType","roleType","RoleId","roleId",nullptr
        };

        NSString* name=readStringCandidate(_api,player,pc,nameFields);
        NSString* role=readStringCandidate(_api,player,pc,roleFields);

        if (!role) {
            int32_t rid=0;
            if (readIntCandidate(_api,player,pc,roleFields,rid))
                role=[NSString stringWithFormat:@"RoleId=%d",(int)rid];
        }

        if (!name) name=@"Player";
        if (!role) role=@"Role 未暴露";

        GGDPlayerSnapshot* snap=[GGDPlayerSnapshot new];
        snap.object=player;
        snap.name=name;
        snap.role=role;
        snap.team=nil;
        snap.hasPosition=NO;
        [_snapshots addObject:snap];
    }

    _status=[NSString stringWithFormat:@"players=%d · Player=%@ · 已自动读取 %lu",
             (int)size, _playerClass?@"OK":@"未知", (unsigned long)_snapshots.count];

    // If role strings are present, the UI can already display them.
    // Numeric role IDs remain explicit until the actual 1.1.13 enum mapping is observed.
}

@end
