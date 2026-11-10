@echo off
setlocal EnableDelayedExpansion
title Necis CBT by Dado - Localhost Launcher

cd /d "%~dp0"
if exist "main_garudacbt_1.5.3_2024_05_07\main\index.php" (
    cd "main_garudacbt_1.5.3_2024_05_07\main"
)
if exist "main\index.php" (
    cd main
)

echo ======================================================================
echo             NECIS CBT BY DADO - LOCALHOST SERVER LAUNCHER            
echo                         SMK NEGERI CIPATUJAH                          
echo ======================================================================
echo.

:: 1. Search for PHP
set "PHP_CMD="
where php >nul 2>nul
if %errorlevel% equ 0 set "PHP_CMD=php"

if not defined PHP_CMD if exist "C:\xampp\php\php.exe" (
    set "PHP_CMD=C:\xampp\php\php.exe"
    set "PATH=C:\xampp\php;!PATH!"
)
if not defined PHP_CMD if exist "D:\xampp\php\php.exe" (
    set "PHP_CMD=D:\xampp\php\php.exe"
    set "PATH=D:\xampp\php;!PATH!"
)
if not defined PHP_CMD if exist "E:\xampp\php\php.exe" (
    set "PHP_CMD=E:\xampp\php\php.exe"
    set "PATH=E:\xampp\php;!PATH!"
)
if not defined PHP_CMD (
    for /d %%D in ("C:\laragon\bin\php\*") do (
        if exist "%%D\php.exe" (
            set "PHP_CMD=%%D\php.exe"
            set "PATH=%%D;!PATH!"
        )
    )
)
if not defined PHP_CMD (
    for /d %%D in ("D:\laragon\bin\php\*") do (
        if exist "%%D\php.exe" (
            set "PHP_CMD=%%D\php.exe"
            set "PATH=%%D;!PATH!"
        )
    )
)

if not defined PHP_CMD goto :NO_PHP

echo [*] PHP terdeteksi: !PHP_CMD!

:: 2. Search for MySQL CLI
set "MYSQL_CMD="
where mysql >nul 2>nul
if %errorlevel% equ 0 set "MYSQL_CMD=mysql"
if not defined MYSQL_CMD if exist "C:\xampp\mysql\bin\mysql.exe" set "MYSQL_CMD=C:\xampp\mysql\bin\mysql.exe"
if not defined MYSQL_CMD if exist "D:\xampp\mysql\bin\mysql.exe" set "MYSQL_CMD=D:\xampp\mysql\bin\mysql.exe"
if not defined MYSQL_CMD if exist "E:\xampp\mysql\bin\mysql.exe" set "MYSQL_CMD=E:\xampp\mysql\bin\mysql.exe"

:: 3. Setup Junction in C:\xampp\htdocs\cbt if XAMPP is present
if exist "C:\xampp\htdocs" (
    if not exist "C:\xampp\htdocs\cbt" (
        powershell -Command "New-Item -ItemType Junction -Path 'C:\xampp\htdocs\cbt' -Target '%CD%' -Force" >nul 2>nul
    )
)

:: 4. Check MySQL and Auto-Init Database
if defined MYSQL_CMD (
    echo [*] Memeriksa koneksi MySQL...
    "!MYSQL_CMD!" -u root -h localhost -e "SHOW DATABASES;" >nul 2>nul
    if !errorlevel! equ 0 (
        echo [OK] MySQL aktif dan siap digunakan.
        "!MYSQL_CMD!" -u root -h localhost -e "USE necis_cbt; SHOW TABLES LIKE 'users';" | findstr "users" >nul 2>nul
        if !errorlevel! neq 0 (
            echo [*] Menyiapkan database necis_cbt dan mengimpor data awal master.sql...
            "!MYSQL_CMD!" -u root -h localhost -e "CREATE DATABASE IF NOT EXISTS necis_cbt CHARACTER SET utf8 COLLATE utf8_general_ci;" >nul 2>nul
            if exist "assets\app\db\master.sql" (
                "!MYSQL_CMD!" -u root -h localhost necis_cbt < "assets\app\db\master.sql" >nul 2>nul
                echo [OK] Database necis_cbt berhasil diinisialisasi otomatis!
            )
        ) else (
            echo [OK] Database necis_cbt sudah terpasang.
        )
    ) else (
        echo [i] Service MySQL belum aktif atau menggunakan password khusus.
    )
)

:: 5. Launch
set "PORT=8080"
echo.
echo ======================================================================
echo  [SERVER AKTIF] Aplikasi Necis CBT by Dado Siap Digunakan!
echo ======================================================================
echo.
echo   Pilihan Akses:
if exist "C:\xampp\htdocs\cbt" (
    echo   1. Melalui Apache XAMPP : http://localhost/cbt/
)
echo   2. Melalui Server Built-in : http://localhost:!PORT!/
echo.
echo   Login Default Admin:
echo     Username : admin
echo     Password : admin
echo.
echo   Tekan Ctrl+C untuk menghentikan server built-in.
echo ======================================================================
echo.

if exist "C:\xampp\apache\bin\httpd.exe" (
    tasklist /fi "imagename eq httpd.exe" | findstr "httpd.exe" >nul
    if !errorlevel! equ 0 (
        start "" "http://localhost/cbt/"
        goto :START_SERVER
    )
)

start "" /b cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:!PORT!/"

:START_SERVER
"!PHP_CMD!" -S localhost:!PORT! router.php
pause
exit /b 0

:NO_PHP
echo [!] PHP tidak ditemukan di sistem atau folder XAMPP/Laragon.
echo.
echo Solusi:
echo  1. Pastikan XAMPP terinstall di C:\xampp atau D:\xampp
echo  2. Atau buka browser langsung ke: http://localhost/cbt/
echo.
pause
exit /b 1
