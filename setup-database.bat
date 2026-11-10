@echo off
setlocal enabledelayedexpansion
title Necis CBT by Dado - Setup Database Localhost

cd /d "%~dp0"
if exist "main_garudacbt_1.5.3_2024_05_07\main\index.php" (
    cd "main_garudacbt_1.5.3_2024_05_07\main"
)
if exist "main\index.php" (
    cd main
)

echo ======================================================================
echo          NECIS CBT BY DADO - SETUP DATABASE OTOMATIS LOCALHOST        
echo                         SMK NEGERI CIPATUJAH                          
echo ======================================================================
echo.

:: 1. Search for MySQL CLI
set "MYSQL_CMD="
where mysql >nul 2>nul
if %errorlevel% equ 0 (
    set "MYSQL_CMD=mysql"
) else if exist "C:\xampp\mysql\bin\mysql.exe" (
    set "MYSQL_CMD=C:\xampp\mysql\bin\mysql.exe"
) else if exist "D:\xampp\mysql\bin\mysql.exe" (
    set "MYSQL_CMD=D:\xampp\mysql\bin\mysql.exe"
) else if exist "E:\xampp\mysql\bin\mysql.exe" (
    set "MYSQL_CMD=E:\xampp\mysql\bin\mysql.exe"
) else (
    for /d %%D in ("C:\laragon\bin\mysql\*\bin") do (
        if exist "%%D\mysql.exe" (
            set "MYSQL_CMD=%%D\mysql.exe"
        )
    )
    for /d %%D in ("D:\laragon\bin\mysql\*\bin") do (
        if exist "%%D\mysql.exe" (
            set "MYSQL_CMD=%%D\mysql.exe"
        )
    )
)

if "%MYSQL_CMD%"=="" (
    echo [!] Program mysql.exe tidak ditemukan di PATH atau folder XAMPP/Laragon.
    echo     Pastikan XAMPP atau Laragon sudah terpasang di komputer Anda.
    echo.
    pause
    exit /b 1
)

echo [*] Menggunakan MySQL CLI: %MYSQL_CMD%
echo.

set "DB_HOST=localhost"
set "DB_USER=root"
set "DB_NAME=necis_cbt"

set /p "INPUT_HOST=Host Database [%DB_HOST%]: "
if not "!INPUT_HOST!"=="" set "DB_HOST=!INPUT_HOST!"

set /p "INPUT_USER=User MySQL [%DB_USER%]: "
if not "!INPUT_USER!"=="" set "DB_USER=!INPUT_USER!"

set /p "INPUT_PASS=Password MySQL (kosongkan jika tanpa password): "
set "DB_PASS=!INPUT_PASS!"

set /p "INPUT_NAME=Nama Database [%DB_NAME%]: "
if not "!INPUT_NAME!"=="" set "DB_NAME=!INPUT_NAME!"

echo.
echo [*] Menguji koneksi MySQL dan membuat database %DB_NAME%...

if "%DB_PASS%"=="" (
    set "AUTH_PARAM=-u %DB_USER% -h %DB_HOST%"
) else (
    set "AUTH_PARAM=-u %DB_USER% -p%DB_PASS% -h %DB_HOST%"
)

"%MYSQL_CMD%" %AUTH_PARAM% -e "CREATE DATABASE IF NOT EXISTS \`%DB_NAME%\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Gagal terhubung ke MySQL.
    echo         Pastikan service MySQL di XAMPP/Laragon sudah AKTIF (START)
    echo         dan username/password sudah sesuai.
    echo.
    pause
    exit /b 1
)

echo [OK] Database %DB_NAME% siap.
echo [*] Mengimpor tabel awal dari assets/app/db/master.sql...

if exist "assets\app\db\master.sql" (
    "%MYSQL_CMD%" %AUTH_PARAM% %DB_NAME% < "assets\app\db\master.sql"
    if %errorlevel% equ 0 (
        echo [OK] Data master.sql berhasil diimpor ke database %DB_NAME%!
    ) else (
        echo [!] Terjadi catatan saat import SQL. Memeriksa tabel...
    )
) else (
    echo [!] File assets\app\db\master.sql tidak ditemukan!
)

:: Update database.php configuration
powershell -Command "$p = 'application/config/database.php'; if (Test-Path $p) { $c = Get-Content $p -Raw; $c = $c -replace \"'hostname' => .*\", \"'hostname' => '%DB_HOST%',\"; $c = $c -replace \"'username' => .*\", \"'username' => '%DB_USER%',\"; $c = $c -replace \"'password' => .*\", \"'password' => '%DB_PASS%',\"; $c = $c -replace \"'database' => .*\", \"'database' => '%DB_NAME%',\"; Set-Content $p -Value $c -Encoding UTF8 -NoNewline; Write-Host '[OK] File application/config/database.php berhasil diperbarui.' }"

echo.
echo ======================================================================
echo  [SUKSES] Setup Database Localhost Berhasil Selesai!
echo ======================================================================
echo.
echo   Host Database : %DB_HOST%
echo   Nama Database : %DB_NAME%
echo   User Database : %DB_USER%
echo.
echo   Sekarang Anda bisa menjalankan 'run-localhost.bat' atau
echo   membuka aplikasi via XAMPP (http://localhost/...)
echo ======================================================================
echo.
pause
