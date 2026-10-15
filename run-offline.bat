@echo off
chcp 65001 >nul
title Atuzz CertAgent Private - 离线一体机一键启动器
echo ================================================================
echo    🚀 正在启动 Atuzz CertAgent Private 企业离线一体机...
echo ================================================================
echo.

:: 1. 检查 Docker 环境
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未检测到 Docker 运行环境！
    echo 请先安装并启动 Docker Desktop 或 Windows 容器引擎。
    pause
    exit /b 1
)

:: 2. 载入离线镜像
if exist "certagent-private-image.tar.gz" (
    echo 📦 检测到离线镜像包 certagent-private-image.tar.gz，正在载入 Docker...
    docker load -i "certagent-private-image.tar.gz"
    echo ✓ 离线镜像已成功载入！
    echo.
) else if exist "certagent-private-latest.tar.gz" (
    echo 📦 检测到离线镜像包 certagent-private-latest.tar.gz，正在载入 Docker...
    docker load -i "certagent-private-latest.tar.gz"
    echo ✓ 离线镜像已成功载入！
    echo.
)

:: 3. 准备数据目录
if not exist "data" mkdir "data"

:: 4. 启动容器
echo ⚙️ 正在执行 Docker Compose 启动...
docker compose up -d
if %errorlevel% neq 0 (
    docker-compose up -d
)

echo.
echo ================================================================
echo    🎉 Atuzz CertAgent Private 企业离线一体机已成功启动！
echo ================================================================
echo.
echo 请在浏览器中打开本地 Web 管理控制台：
echo 👉 https://127.0.0.1:3443 (HTTPS 绿锁管理控制台)
echo 👉 http://127.0.0.1:3000 (HTTP 探针中枢与根证书极速分发)
echo.
echo 💡 首次登录提示：
echo    系统已内置「首次安全向导」，打开页面后请直接自主设定管理员密码。
echo.
pause
