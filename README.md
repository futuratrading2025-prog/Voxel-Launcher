# Voxel Launcher

Minecraft Java 版手机启动器（Flutter）。

## 运行前需要做的事

1. 安装依赖：`flutter pub get`
2. **申请微软登录用的 Client ID**（用于正版校验）：
   - 打开 https://portal.azure.com → Azure Active Directory → 应用注册 → 新注册
   - 支持的账户类型选"任何组织目录中的账户和个人 Microsoft 账户"
   - 平台选"移动应用和桌面应用程序"，重定向 URI 用官方给的
     `https://login.microsoftonline.com/common/oauth2/nativeclient`
   - 注册完成后复制"应用程序(客户端) ID"，填入
     `lib/services/msa_auth_service.dart` 里的 `clientId`
   - 这是官方开放给第三方启动器接入的标准流程（PCL/HMCL 都是这么做的）

## 已实现

- 正版登录（微软账号设备码流程，自动校验 Java 版持有权）
- 离线登录（本地生成离线 UUID）
- 游戏版本安装（官方 Mojang 版本清单，jar 带 SHA1 校验）
- 光影 / 模组 / 整合包在线搜索安装（Modrinth 官方 API）
- 光影包 / 模组 / 整合包本地导入入口（文件选择已接好，复制到目标版本目录的逻辑待你按需补全）

## 还没做、需要你继续开发的部分

- **游戏实际启动（JVM 运行时）**：Android 不能直接跑 Java 程序，需要移植版
  JRE + 图形层转换（OpenGL→GLES/Vulkan），这是独立的大工程，建议参考开源
  项目 PojavLauncher / Zalith Launcher 的运行时方案，做成原生模块接入。
- 整合包（.mrpack）导入后的依赖解析与批量下载
- 皮肤管理、多账号切换、启动参数自定义等

## 关于你之前提供的下载链接

原本你给的 26.2.jar / json 是通过个人网盘分享的，我没有采用 —— 原因：
1. Minecraft 官方没有"26.2"这个版本号，来源不明的文件有安全风险
2. 游戏客户端属于 Mojang/Microsoft 版权内容，用私人网盘链接分发不合规

现在的实现改为直接对接 Mojang 官方版本清单接口，用户在"游戏版本安装"里
选择的都是真实存在、来源可信的官方版本。
