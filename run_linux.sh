#!/bin/bash

echo "Plants vs Zombies .NET - Linux移植版本"
echo "======================================"

# 检查.NET 8.0是否安装
if ! command -v dotnet &> /dev/null; then
    echo "错误：未找到dotnet命令。请安装.NET 8.0 SDK。"
    echo "安装命令：sudo apt install dotnet-sdk-8.0"
    exit 1
fi

# 检查unzip是否安装
if ! command -v unzip &> /dev/null; then
    echo "错误：未找到unzip命令。请安装unzip。"
    echo "安装命令：sudo apt install unzip"
    exit 1
fi

# 检查.NET版本
dotnet_version=$(dotnet --version)
echo "当前.NET版本：$dotnet_version"

# 定义资源文件
PCGL_RESOURCE_FILE="Resource_Pack_for_PCGL_and_Android.zip"
CHN_RESOURCE_FILE="Content_ExtraFont_and_CHN.zip"
PCDX_RESOURCE_FILE="Resource_Pack_for_PCDX.zip"

# 自动处理资源文件
setup_resources() {
    local config=$1
    local target_dir="Lawn_PCGL/bin/$config/net8.0"
    local resource_file=$2
    
    if [ ! -f "$resource_file" ]; then
        echo "错误：未找到资源文件 $resource_file"
        echo "请确保资源文件在项目根目录下。"
        return 1
    fi
    
    echo "正在为$config版本解压资源文件 $resource_file..."
    unzip -o "$resource_file" -d "$target_dir/" >/dev/null 2>&1
    echo "资源文件已准备好。"
    return 0
}

# 移除资源文件
remove_resources() {
    local configs=("Debug" "Release")
    
    echo "正在移除所有资源文件..."
    
    for config in "${configs[@]}"; do
        local target_dir="Lawn_PCGL/bin/$config/net8.0/Content"
        if [ -d "$target_dir" ]; then
            rm -rf "$target_dir"
            echo "已移除 $config 版本的资源文件"
        fi
    done
    
    echo "所有资源文件已移除。"
}

# 检查资源文件状态
check_resource_status() {
    echo ""
    echo "=== 资源文件状态 ==="
    
    # 检查资源包文件
    echo "可用的资源包："
    [ -f "$PCGL_RESOURCE_FILE" ] && echo "  ✅ $PCGL_RESOURCE_FILE (PCGL版本基础资源)" || echo "  ❌ $PCGL_RESOURCE_FILE (缺失)"
    [ -f "$CHN_RESOURCE_FILE" ] && echo "  ✅ $CHN_RESOURCE_FILE (中文字体和汉化)" || echo "  ❌ $CHN_RESOURCE_FILE (缺失)"
    [ -f "$PCDX_RESOURCE_FILE" ] && echo "  ✅ $PCDX_RESOURCE_FILE (PCDX版本资源)" || echo "  ❌ $PCDX_RESOURCE_FILE (缺失)"
    
    echo ""
    echo "已安装的资源："
    
    # 检查Debug版本
    if [ -d "Lawn_PCGL/bin/Debug/net8.0/Content" ]; then
        if [ -f "Lawn_PCGL/bin/Debug/net8.0/Content/LawnStrings_zh_cn.txt" ]; then
            echo "  ✅ Debug版本资源已安装 (包含中文汉化)"
        else
            echo "  ✅ Debug版本资源已安装 (仅基础资源)"
        fi
    else
        echo "  ❌ Debug版本资源未安装"
    fi
    
    # 检查Release版本
    if [ -d "Lawn_PCGL/bin/Release/net8.0/Content" ]; then
        if [ -f "Lawn_PCGL/bin/Release/net8.0/Content/LawnStrings_zh_cn.txt" ]; then
            echo "  ✅ Release版本资源已安装 (包含中文汉化)"
        else
            echo "  ✅ Release版本资源已安装 (仅基础资源)"
        fi
    else
        echo "  ❌ Release版本资源未安装"
    fi
    
    # 如果有汉化资源，显示详细信息
    if [ -f "Lawn_PCGL/bin/Debug/net8.0/Content/LawnStrings_zh_cn.txt" ] || [ -f "Lawn_PCGL/bin/Release/net8.0/Content/LawnStrings_zh_cn.txt" ]; then
        echo ""
        echo "汉化资源详情："
        [ -f "Lawn_PCGL/bin/Debug/net8.0/Content/fonts/LXGWWenKai-Bold.ttf" ] && echo "  ✅ 中文字体已安装"
        [ -d "Lawn_PCGL/bin/Debug/net8.0/Content/images/480x800/zh_cn" ] && echo "  ✅ 中文本地化图像已安装"
    fi
    
    echo ""
}

# 添加基础资源文件
add_base_resources() {
    if [ ! -f "$PCGL_RESOURCE_FILE" ]; then
        echo "错误：未找到基础资源文件 $PCGL_RESOURCE_FILE"
        echo "请确保该文件在项目根目录下。"
        return 1
    fi
    
    local configs=("Debug" "Release")
    echo "正在添加基础资源文件..."
    
    for config in "${configs[@]}"; do
        # 确保目录存在
        mkdir -p "Lawn_PCGL/bin/$config/net8.0"
        setup_resources "$config" "$PCGL_RESOURCE_FILE"
    done
    
    echo "基础资源文件添加完成。"
}

# 添加汉化资源文件
add_chinese_resources() {
    if [ ! -f "$CHN_RESOURCE_FILE" ]; then
        echo "错误：未找到汉化资源文件 $CHN_RESOURCE_FILE"
        echo "请确保该文件在项目根目录下。"
        return 1
    fi
    
    local configs=("Debug" "Release")
    echo "正在添加汉化资源文件..."
    
    for config in "${configs[@]}"; do
        # 确保目录存在
        mkdir -p "Lawn_PCGL/bin/$config/net8.0"
        
        # 如果基础资源不存在，先添加基础资源
        if [ ! -d "Lawn_PCGL/bin/$config/net8.0/Content" ]; then
            echo "检测到缺少基础资源，正在添加基础资源..."
            if ! setup_resources "$config" "$PCGL_RESOURCE_FILE"; then
                echo "错误：无法添加基础资源，请先确保 $PCGL_RESOURCE_FILE 存在。"
                return 1
            fi
        fi
        
        # 覆盖安装汉化资源（-o参数确保覆盖现有文件）
        echo "正在为$config版本覆盖安装汉化资源..."
        unzip -o "$CHN_RESOURCE_FILE" -d "Lawn_PCGL/bin/$config/net8.0/" >/dev/null 2>&1
        echo "$config版本汉化资源安装完成。"
    done
    
    echo "汉化资源文件添加完成。"
    echo "包含内容："
    echo "  - 中文字符串文件 (LawnStrings_zh_cn.txt)"
    echo "  - 中文字体文件 (LXGWWenKai-Bold.ttf, SourceHanSansSC-Heavy.otf, TiejiliSC-Regular.ttf)"
    echo "  - 中文本地化图像 (zh_cn目录)"
}

# 智能资源安装（在构建或运行时自动检查）
smart_resource_setup() {
    local config=$1
    local target_dir="Lawn_PCGL/bin/$config/net8.0"
    
    if [ ! -d "$target_dir/Content" ]; then
        echo "检测到缺少资源文件，正在自动安装..."
        if [ -f "$PCGL_RESOURCE_FILE" ]; then
            setup_resources "$config" "$PCGL_RESOURCE_FILE"
        else
            echo "警告：未找到资源文件 $PCGL_RESOURCE_FILE"
            echo "游戏可能无法正常运行。请先添加资源文件。"
            return 1
        fi
    fi
}

echo ""
echo "可用操作："
echo "1. 构建整个项目"
echo "2. 运行主游戏（Debug版本）"
echo "3. 运行主游戏（Release版本）"
echo "4. 运行Python交互客户端"
echo "5. 清理构建输出"
echo "6. 资源文件管理"
echo "7. 退出"

while true; do
    echo ""
    read -p "请选择操作 (1-7): " choice
    
    case $choice in
        1)
            echo "正在构建项目..."
            dotnet restore Lawn_Linux.sln
            dotnet build Lawn_Linux.sln
            smart_resource_setup "Debug"
            smart_resource_setup "Release"
            echo "构建完成。"
            ;;
        2)
            echo "启动主游戏（Debug版本）..."
            smart_resource_setup "Debug"
            dotnet run --project Lawn_PCGL/Lawn_PCGL.csproj --configuration Debug
            ;;
        3)
            echo "启动主游戏（Release版本）..."
            smart_resource_setup "Release"
            dotnet run --project Lawn_PCGL/Lawn_PCGL.csproj --configuration Release
            ;;
        4)
            echo "启动Python交互客户端..."
            dotnet run --project IronPyInteractiveClient_Avalonia/IronPyInteractiveClient_Avalonia.csproj
            ;;
        5)
            echo "清理构建输出..."
            dotnet clean Lawn_Linux.sln
            find . -name "bin" -type d -exec rm -rf {} + 2>/dev/null
            find . -name "obj" -type d -exec rm -rf {} + 2>/dev/null
            echo "清理完成。"
            ;;
        6)
            # 资源文件管理子菜单
            while true; do
                check_resource_status
                echo "=== 资源文件管理 ==="
                echo "1. 添加基础资源文件（PCGL版本）"
                echo "2. 添加汉化资源文件（中文字体+汉化）"
                echo "3. 移除所有资源文件"
                echo "4. 查看资源文件状态"
                echo "5. 返回主菜单"
                echo ""
                read -p "请选择操作 (1-5): " resource_choice
                
                case $resource_choice in
                    1)
                        add_base_resources
                        ;;
                    2)
                        add_chinese_resources
                        ;;
                    3)
                        remove_resources
                        ;;
                    4)
                        check_resource_status
                        read -p "按回车键继续..."
                        ;;
                    5)
                        break
                        ;;
                    *)
                        echo "无效选择，请输入1-5之间的数字。"
                        ;;
                esac
            done
            ;;
        7)
            echo "退出。"
            exit 0
            ;;
        *)
            echo "无效选择，请输入1-7之间的数字。"
            ;;
    esac
done