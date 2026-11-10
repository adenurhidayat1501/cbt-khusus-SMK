@echo off
setlocal enabledelayedexpansion
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
if %errorlevel% equ 0 (
    set "PHP_CMD=php"
    goto :FOUND_PHP
)

:: Search common XAMPP & Laragon paths
if exist "C:\xampp\php\php.exe" (
    set "PHP_CMD=C:\xampp\php\php.exe"
    set "PATH=C:\xampp\php;!PATH!"
    goto :FOUND_PHP
)
if exist "D:\xampp\php\php.exe" (
    set "PHP_CMD=D:\xampp\php\php.exe"
    set "PATH=D:\xampp\php;!PATH!"
    goto :FOUND_PHP
)
if exist "E:\xampp\php\php.exe" (
    set "PHP_CMD=E:\xampp\php\php.exe"
    set "PATH=E:\xampp\php;!PATH!"
    goto :FOUND_PHP
)

for /d %%D in ("C:\laragon\bin\php\*") do (
    if exist "%%D\php.exe" (
        set "PHP_CMD=%%D\php.exe"
        set "PATH=%%D;!PATH!"
        goto :FOUND_PHP
    )
)
for /d %%D in ("D:\laragon\bin\php\*") do (
    if exist "%%D\php.exe" (
        set "PHP_CMD=%%D\php.exe"
        set "PATH=%%D;!PATH!"
        goto :FOUND_PHP
    )
)

:FOUND_PHP
if "%PHP_CMD%"=="" (
    echo [!] PHP tidak ditemukan di sistem atau folder XAMPP/Laragon.
    echo.
    echo Pilihan cara menjalankan di localhost:
    echo  1. Buka XAMPP Control Panel, START Apache dan MySQL.
    echo     Lalu buka browser: http://localhost/cbt (atau folder tempat Anda menyimpan)
    echo.
    echo  2. Atau install PHP via Windows Package Manager (winget):
    echo     Jalankan di CMD: winget install PHP.PHP -e
    echo.
    pause
    exit /b 1
)

echo [*] PHP terdeteksi: %PHP_CMD%

:: 2. Search for MySQL CLI
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
)

:: 3. Check and Auto-Init Database if MySQL is running
if not "%MYSQL_CMD%"=="" (
    echo [*] Memeriksa koneksi MySQL...
    "%MYSQL_CMD%" -u root -h localhost -e "SHOW DATABASES;" >nul 2>nul
    if !errorlevel! equ 0 (
        echo [OK] MySQL aktif dan siap digunakan.
        "%MYSQL_CMD%" -u root -h localhost -e "USE necis_cbt; SHOW TABLES LIKE 'users';" | findstr "users" >nul 2>nul
        if !errorlevel! neq 0 (
            echo [*] Membuat database necis_cbt dan mengimpor data awal (master.sql)...
            "%MYSQL_CMD%" -u root -h localhost -e "CREATE DATABASE IF NOT EXISTS necis_cbt CHARACTER SET utf8 COLLATE utf8_general_ci;" >nul 2>nul
            if exist "assets\app\db\master.sql" (
                "%MYSQL_CMD%" -u root -h localhost necis_cbt < "assets\app\db\master.sql" >nul 2>nul
                echo [OK] Database necis_cbt berhasil diinisialisasi otomatis!
            )
        ) else (
            echo [OK] Database necis_cbt sudah terpasang.
        )
    ) else (
        echo [i] MySQL belum aktif atau menggunakan password.
        echo     (Pastikan service MySQL di XAMPP/Laragon sudah di-START)
    )
)

:: 4. Start PHP Built-in Server on port 8080 or next available
set "PORT=8080"
echo.
echo ======================================================================
echo  [SERVER BERJALAN] Aplikasi Necis CBT by Dado aktif di Localhost!
echo ======================================================================
echo.
echo   URL Aplikasi   : http://localhost:!PORT!/
echo   URL Installer  : http://localhost:!PORT!/installer/
echo.
echo   Login Default  :
echo     Username     : admin
echo     Password     : admin
echo.
echo   Tekan tombol Ctrl+C di jendela ini untuk mematikan server.
echo ======================================================================
echo.

:: Open default browser after 2 seconds in background
start "" /b cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:!PORT!/"

:: Launch built-in server with router.php
"%PHP_CMD%" -S localhost:!PORT! router.php
pause
