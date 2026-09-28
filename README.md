# GGDIdentityOverlay — 1.1.13 独立实现

目标进程：`com.seayoo.ggd`

这套工程不以旧插件二进制作为链接/代码基底。它从 UnityFramework 运行时动态解析 IL2CPP API，先建立运行时连接，再从 `GooseGame.players` 获取玩家集合。

## 当前设计

1. 启动后等待 UnityFramework。
2. `dlopen` / `dlsym` 查找 IL2CPP API。
3. `il2cpp_domain_get` + `il2cpp_thread_attach` 建立当前线程的 IL2CPP 上下文。
4. 枚举程序集，尝试定位 `GooseGame`。
5. 尝试定位静态字段 `players`。
6. UI 实时显示：
   - 是否真正注入
   - IL2CPP 是否连接
   - GooseGame 是否找到
   - players 是否初始化
   - 当前玩家数量
7. 后续角色读取只使用目标版本实际暴露出来的字段，不硬编码旧插件的偏移。

## 为什么没有把文件硬塞到 20 MB

体积不是功能证明。真正的 20 MB 插件通常包含完整 ImGui/Metal、调试数据、C++ runtime 或大量业务代码。这里优先保证代码可维护、可重新编译、可验证。需要体积时应来自真实依赖和代码，而不是填充垃圾段。

## 构建

需要 macOS + Xcode/iPhoneOS SDK + Theos。

将工程放入 Theos 环境：

```sh
make package FINALPACKAGE=1
```

产物为：

`packages/com.example.ggdidentityoverlay_*.deb`

再把其中的 dylib 放进签名工具的第三方库列表。

## 下一步

安装后先看悬浮窗：

- `GGD 已加载`
- `Unity/IL2CPP: OK`
- `Game: OK`
- `Players: ...`

只有这四项跑通后，才进入 Player 实例字段自动发现和真实身份/坐标绘制。这样可以把“插件没加载”和“游戏数据解析失败”完全分开。


## v2 runtime extractor

这一版比 v1 多了一层真正的 `List<T>` → `Player` 自动读取：

- 通过 `GooseGame.players` 获取静态玩家集合。
- 从 `List<T>._items` / `_size` 读取当前玩家对象。
- 通过 `il2cpp_object_get_class` 获取 Player 运行时类型。
- 尝试读取 Name/PlayerName/Nickname 等字段。
- 尝试读取 RoleName/Role/CurrentRole/RoleType/RoleId 等字段。
- 如果角色是字符串，直接显示；如果是整数/枚举，显示 `RoleId=N`，不凭空猜映射。
- 悬浮窗直接列出前 6 个检测到的玩家及角色结果。

这是为了让第一次实机测试就能把“运行时连接”和“真实 Player 数据”区分开。拿到 1.1.13 实机字段结果后，再固定精确字段与角色枚举映射。


## GitHub Actions 编译

这个仓库自带 `.github/workflows/build.yml`。GitHub Actions 使用 macOS runner + Apple iPhoneOS SDK 编译真正的 arm64 Mach-O dylib。

在 GitHub 网页上：
1. 新建一个空仓库。
2. 上传本目录的全部文件（包括 `.github/workflows/build.yml`）。
3. 打开仓库的 Actions。
4. 选择 `Build GGDIdentityOverlay`。
5. 点 `Run workflow`。
6. 完成后在该次 workflow 的 Artifacts 下载 `GGDIdentityOverlay-arm64`。

生成的 dylib 是未签名的，交给你的签名/注入工具签名即可。不要在 GitHub 中放 Apple 证书、私钥或 provisioning profile。
