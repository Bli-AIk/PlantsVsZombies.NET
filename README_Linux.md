# Plants vs Zombies .NET - Linux移植版本

这是植物大战僵尸.NET版本的Linux移植，包含了以下改进：

## 主要变更

### 1. 兼容性改进
- 更新.NET版本从7.0到8.0以兼容当前系统
- 使用MonoGame.Framework.DesktopGL替代Windows专用的DirectX版本
- 移除了Android和Windows专用项目的依赖

### 2. WPF替换为Avalonia
- 创建了`IronPyInteractiveClient_Avalonia`项目来替换原有的WPF客户端
- 保持了原有的功能：WebSocket连接、Python命令执行、输出显示
- 支持跨平台运行（Linux、macOS、Windows）

### 3. 项目结构
- `Lawn_Linux.sln` - Linux兼容的解决方案文件
- `Lawn_PCGL/` - 主游戏项目（使用OpenGL）
- `IronPyInteractiveClient_Avalonia/` - Python交互客户端（Avalonia UI）
- 共享项目保持不变

## 构建和运行

### 前置要求
- .NET 8.0 SDK
- Linux桌面环境（支持X11或Wayland）

### 构建项目
```bash
# 进入项目目录
cd /path/to/PlantsVsZombies.NET

# 恢复NuGet包
dotnet restore Lawn_Linux.sln

# 构建整个解决方案
dotnet build Lawn_Linux.sln
```

### 运行游戏
```bash
# 运行主游戏（需要Content资源文件）
dotnet run --project Lawn_PCGL/Lawn_PCGL.csproj

# 运行Python交互客户端
dotnet run --project IronPyInteractiveClient_Avalonia/IronPyInteractiveClient_Avalonia.csproj
```

## 注意事项

### 1. 资源文件
游戏需要Content资源文件包才能正常运行。请确保：
- 将资源文件解压到游戏可执行文件目录下
- Content文件夹与游戏可执行文件在同一目录

### 2. Python交互功能
- Avalonia版本的Python客户端功能与原WPF版本相同
- 支持WebSocket连接到游戏进行IronPython脚本执行
- 默认连接地址：`ws://localhost:8080/Py`

### 3. 系统兼容性
- 已在Linux系统上测试通过
- 需要OpenGL支持（大多数现代Linux发行版都支持）
- 如果遇到图形问题，请确保显卡驱动正确安装

## 已知问题
1. 游戏启动时会显示缺少资源文件的错误（需要从原项目获取Content资源包）
2. 一些Windows特定的代码可能产生警告，但不影响Linux下的运行

## 开发说明
- 使用`Lawn_Linux.sln`而不是原来的`Lawn.sln`来避免Windows专用项目的构建问题
- 如需添加新功能，建议优先考虑跨平台兼容性
- 对于UI相关功能，建议使用Avalonia而不是WPF

## 获取资源文件
资源文件包请从原项目说明中的联系方式获取：
- 项目交流群：884792079
- Discord：[discord.gg/uXz6g6Adnm](https://discord.gg/uXz6g6Adnm)