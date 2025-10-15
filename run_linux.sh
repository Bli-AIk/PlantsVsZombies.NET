#!/bin/bash

echo "Plants vs Zombies .NET - Linux移植版本"
echo "======================================"

# 检查.NET 8.0是否安装
if ! command -v dotnet &> /dev/null; then
    echo "错误：未找到dotnet命令。请安装.NET 8.0 SDK。"
    echo "安装命令：sudo apt install dotnet-sdk-8.0"
    exit 1
fi

# 检查.NET版本
dotnet_version=$(dotnet --version)
echo "当前.NET版本：$dotnet_version"

echo ""
echo "可用操作："
echo "1. 构建整个项目"
echo "2. 运行主游戏（需要Content资源文件）"
echo "3. 运行Python交互客户端"
echo "4. 清理构建输出"
echo "5. 退出"

while true; do
    echo ""
    read -p "请选择操作 (1-5): " choice
    
    case $choice in
        1)
            echo "正在构建项目..."
            dotnet restore Lawn_Linux.sln
            dotnet build Lawn_Linux.sln
            echo "构建完成。"
            ;;
        2)
            echo "启动主游戏..."
            echo "注意：如果显示资源文件错误，请确保Content文件夹在可执行文件目录下。"
            dotnet run --project Lawn_PCGL/Lawn_PCGL.csproj
            ;;
        3)
            echo "启动Python交互客户端..."
            dotnet run --project IronPyInteractiveClient_Avalonia/IronPyInteractiveClient_Avalonia.csproj
            ;;
        4)
            echo "清理构建输出..."
            dotnet clean Lawn_Linux.sln
            find . -name "bin" -type d -exec rm -rf {} + 2>/dev/null
            find . -name "obj" -type d -exec rm -rf {} + 2>/dev/null
            echo "清理完成。"
            ;;
        5)
            echo "退出。"
            exit 0
            ;;
        *)
            echo "无效选择，请输入1-5之间的数字。"
            ;;
    esac
done