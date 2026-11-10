@echo off
setlocal enabledelayedexpansion
title Necis CBT by Dado - Push to GitHub Helper

cd /d "%~dp0"
if exist "cbt-sekolah-main\index.php" (
    cd cbt-sekolah-main
)
if exist "main\index.php" (
    cd main
)

echo ======================================================================
echo          Necis CBT by Dado - PUSH TO GITHUB AUTOMATION HELPER                
echo              SMK NEGERI CIPATUJAH                         
echo ======================================================================
echo.

:: 1. Check if git exists in PATH or standard directories
where git >nul 2>nul
if %errorlevel% neq 0 (
    if exist "C:\Program Files\Git\cmd\git.exe" (
        set "PATH=%PATH%;C:\Program Files\Git\cmd"
    ) else if exist "C:\Program Files (x86)\Git\cmd\git.exe" (
        set "PATH=%PATH%;C:\Program Files (x86)\Git\cmd"
    ) else if exist "%LOCALAPPDATA%\Programs\Git\cmd\git.exe" (
        set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Git\cmd"
    ) else (
        echo [!] Git belum terdeteksi di komputer Anda.
        where winget >nul 2>nul
        if %errorlevel% equ 0 (
            echo Sistem mendeteksi winget. Menginstall Git for Windows secara otomatis...
            winget install --id Git.Git -e --source winget
            if exist "C:\Program Files\Git\cmd\git.exe" set "PATH=%PATH%;C:\Program Files\Git\cmd"
            if exist "%LOCALAPPDATA%\Programs\Git\cmd\git.exe" set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Git\cmd"
        ) else (
            echo Silakan download dan install Git for Windows terlebih dahulu:
            echo    https://git-scm.com/download/win
            echo.
            echo Setelah install Git, jalankan kembali script ini.
            pause
            exit /b 1
        )
    )
)

echo [OK] Git terdeteksi di sistem.
echo.

:: 2. Auto-configure Git User and disable LF/CRLF warnings
git config --global user.name >nul 2>nul
if %errorlevel% neq 0 (
    echo [*] Mengatur identitas Git user.name & user.email...
    git config --global user.name "SMK Negeri Cipatujah"
    git config --global user.email "admin@smkncipatujah.sch.id"
)
git config core.autocrlf false >nul 2>nul

:: 3. Prompt for GitHub Repository URL
set "REPO_URL="
set /p "REPO_URL=Masukkan URL Repository GitHub Anda [Enter untuk https://github.com/adenurhidayat1501/cbt-sekolah.git]: "

if "%REPO_URL%"=="" (
    set "REPO_URL=https://github.com/adenurhidayat1501/cbt-sekolah.git"
)

echo.
echo [*] Menggunakan repository: %REPO_URL%
echo [*] Menyiapkan repository lokal...

:: 4. Initialize Git if not initialized
if not exist ".git" (
    git init
    echo [OK] Git repository berhasil diinisialisasi.
)

:: 5. Add files & Commit
echo [*] Menambahkan berkas ke Git (git add .)...
git add .

echo [*] Membuat commit...
git commit -m "Necis CBT by Dado - SMK NEGERI CIPATUJAH" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Commit berhasil dibuat.
) else (
    echo [i] Tidak ada perubahan baru yang perlu di-commit.
)

:: 6. Set main branch & remote origin
git branch -M main >nul 2>&1
git remote remove origin >nul 2>&1
git remote add origin %REPO_URL%

:: 7. Push to GitHub
echo.
echo ======================================================================
echo Mengunggah ke GitHub (%REPO_URL%)...
echo - Jika muncul jendela browser, silakan klik 'Sign in with your browser'.
echo - Jika diminta password di terminal, gunakan Personal Access Token (PAT).
echo ======================================================================
echo.

:: Try normal push first
git push -u origin main

if %errorlevel% equ 0 (
    goto :SUCCESS
)

echo.
echo [!] Push normal ditolak (kemungkinan karena repository di GitHub sudah memiliki commit berbeda).
echo Apakah Anda ingin menimpa (force push) repository di GitHub dengan versi lokal ini?
set /p "FORCE_CHOICE=Timpa repository GitHub sekarang? (y/n) [y]: "
if "%FORCE_CHOICE%"=="" set "FORCE_CHOICE=y"

if /i "%FORCE_CHOICE%"=="y" (
    echo [*] Menjalankan git push --force...
    git push -u origin main --force
    if !errorlevel! equ 0 goto :SUCCESS
)

echo.
echo [WARNING] Terjadi kendala saat push ke GitHub.
echo Kemungkinan penyebab:
echo 1. Anda belum login atau token GitHub tidak memiliki izin 'repo'.
echo 2. Password akun biasa ditolak oleh GitHub (harus gunakan Personal Access Token).
echo.
pause
exit /b 1

:SUCCESS
echo.
echo ======================================================================
echo [SUKSES] Source code Necis CBT by Dado berhasil di-upload ke GitHub!
echo.
echo Sekarang untuk install di VPS Anda, cukup jalankan di VPS (SSH):
echo.
echo    git clone %REPO_URL% /var/www/necis_cbt
echo    cd /var/www/necis_cbt
echo    sudo bash install-vps.sh -y
echo.
echo ======================================================================
echo.
pause
