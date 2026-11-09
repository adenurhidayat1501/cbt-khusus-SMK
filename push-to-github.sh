#!/usr/bin/env bash
# ==============================================================================
# Garuda CBT - Push to GitHub Automation Helper (Linux / macOS / Git Bash)
# ==============================================================================

set -e

if [ -f "main/index.php" ]; then
    cd main
fi

echo "======================================================================"
echo "          GARUDA CBT - PUSH TO GITHUB AUTOMATION HELPER                "
echo "======================================================================"
echo ""

if ! command -v git &> /dev/null; then
    echo "[ERROR] Git belum terinstall! Silakan install git terlebih dahulu."
    exit 1
fi

read -p "Masukkan URL Repository GitHub Anda (contoh: https://github.com/username/garudacbt.git): " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo "[ERROR] URL repository tidak boleh kosong!"
    exit 1
fi

if [ ! -d ".git" ]; then
    git init
    echo "[OK] Git repository berhasil diinisialisasi."
fi

git add .
git commit -m "Garuda CBT - Modern UI/UX and Automated VPS Deployment" || true
git branch -M main

git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"

echo ""
echo "--> Mengunggah source code ke GitHub ($REPO_URL)..."
git push -u origin main

echo ""
echo "======================================================================"
echo "[SUKSES] Source code Garuda CBT berhasil diunggah ke GitHub!"
echo "Untuk menginstall di VPS, jalankan di terminal VPS (SSH):"
echo ""
echo "   git clone $REPO_URL /var/www/garudacbt"
echo "   cd /var/www/garudacbt"
echo "   sudo bash install-vps.sh"
echo "======================================================================"
