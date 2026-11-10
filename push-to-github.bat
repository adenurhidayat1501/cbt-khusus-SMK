@echo off
setlocal enabledelayedexpansion
title SADUCI CBT - Push to GitHub Helper

cd /d "%~dp0"
if exist "main\index.php" (
    cd main
)

echo ======================================================================
echo          SADUCI CBT - PUSH TO GITHUB AUTOMATION HELPER                
echo              SMP NEGERI SATU ATAP 2 CIPATUJAH                         
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

:: 2. Prompt for GitHub Repository URL
set "REPO_URL="
set /p "REPO_URL=Masukkan URL Repository GitHub Anda (contoh: https://github.com/adenurhidayat1501/cbt-sekolah.git): "

if "%REPO_URL%"=="" (
    echo [ERROR] URL repository tidak boleh kosong!
    pause
    exit /b 1
)

echo.
echo [*] Menyiapkan repository lokal...

:: 3. Initialize Git if not initialized
if not exist ".git" (
    git init
    echo [OK] Git repository berhasil diinisialisasi.
)

:: 4. Add files
echo [*] Menambahkan berkas ke Git (git add .)...
git add .

:: 5. Commit
echo [*] Membuat commit...
git commit -m "SADUCI CBT - Rebranded for SMP Negeri Satu Atap 2 Cipatujah"

:: 6. Set main branch & remote origin
echo [*] Mengatur branch utama ke 'main'...
git branch -M main

git remote remove origin 2>nul
git remote add origin %REPO_URL%

:: 7. Push
echo.
echo ======================================================================
echo Mengunggah ke GitHub (%REPO_URL%)...
echo Jika diminta login, silakan masukkan Personal Access Token atau login via browser.
echo ======================================================================
echo.

git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ======================================================================
    echo [SUKSES] Source code SADUCI CBT berhasil di-upload ke GitHub!
    echo.
    echo Sekarang untuk install di VPS Anda, cukup jalankan di VPS (SSH):
    echo.
    echo    git clone %REPO_URL% /var/www/saduci_cbt
    echo    cd /var/www/saduci_cbt
    echo    sudo bash install-vps.sh -y
    echo.
    echo ======================================================================
) else (
    echo.
    echo [WARNING] Terjadi kendala saat push ke GitHub.
    echo Pastikan repository sudah dibuat di GitHub dan Anda memiliki hak akses.
)

echo.
pause
