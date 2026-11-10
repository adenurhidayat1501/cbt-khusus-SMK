#!/usr/bin/env bash
# ==============================================================================
# SADUCI CBT - Push to GitHub Automation Helper (Linux / macOS / Git Bash)
# SMP NEGERI SATU ATAP 2 CIPATUJAH
# ==============================================================================

set -e

if [ -f "main/index.php" ]; then
    cd main
fi

echo "======================================================================"
echo "          SADUCI CBT - PUSH TO GITHUB AUTOMATION HELPER                "
echo "              SMP NEGERI SATU ATAP 2 CIPATUJAH                         "
echo "======================================================================"
echo ""

if ! command -v git &> /dev/null; then
    echo "[ERROR] Git belum terinstall! Silakan install git terlebih dahulu."
    exit 1
fi

read -p "Masukkan URL Repository GitHub Anda (contoh: https://github.com/adenurhidayat1501/cbt-sekolah.git): " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo "[ERROR] URL repository tidak boleh kosong!"
    exit 1
fi

if [ ! -d ".git" ]; then
    git init
    echo "[OK] Git repository berhasil diinisialisasi."
fi

git add .
git commit -m "SADUCI CBT - Rebranded for SMP Negeri Satu Atap 2 Cipatujah" || true
git branch -M main

git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"

echo ""
echo "--> Mengunggah source code ke GitHub ($REPO_URL)..."
git push -u origin main

echo ""
echo "======================================================================"
echo "[SUKSES] Source code SADUCI CBT berhasil diunggah ke GitHub!"
echo "Untuk menginstall di VPS, jalankan di terminal VPS (SSH):"
echo ""
echo "   git clone $REPO_URL /var/www/saduci_cbt"
echo "   cd /var/www/saduci_cbt"
echo "   sudo bash install-vps.sh -y"
echo "======================================================================"
