#!/usr/bin/env bash
# ==============================================================================
# SADUCI CBT - Automated VPS Installer Script (Ubuntu / Debian)
# SMP NEGERI SATU ATAP 2 CIPATUJAH
# Modernized Edition (2024-2026)
# ==============================================================================
# Usage:
#   sudo bash install-vps.sh
#   sudo bash install-vps.sh -y   (Non-interactive / Auto-install)
# ==============================================================================

set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# 1. Root and Environment Check
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Skrip ini harus dijalankan sebagai root atau dengan sudo!${NC}"
    echo -e "Silakan jalankan: ${CYAN}sudo bash install-vps.sh${NC}"
    exit 1
fi

echo -e "${CYAN}${BOLD}"
echo "======================================================================"
echo "          SADUCI CBT - AUTOMATED VPS INSTALLER SCRIPT                 "
echo "              SMP NEGERI SATU ATAP 2 CIPATUJAH                        "
echo "                 Modernized Edition (2024-2026)                       "
echo "======================================================================"
echo -e "${NC}"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VER=$VERSION_ID
else
    echo -e "${RED}[ERROR] Sistem Operasi tidak terdeteksi.${NC}"
    exit 1
fi

if [[ "$OS_NAME" != "ubuntu" && "$OS_NAME" != "debian" ]]; then
    echo -e "${YELLOW}[WARNING] Skrip ini dioptimalkan untuk Ubuntu/Debian. Melanjutkan dengan risiko sendiri...${NC}"
fi

# Detect application source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/index.php" ]; then
    SRC_DIR="$SCRIPT_DIR"
elif [ -f "$SCRIPT_DIR/main/index.php" ]; then
    SRC_DIR="$SCRIPT_DIR/main"
else
    SRC_DIR="$PWD"
fi

if [ ! -f "$SRC_DIR/index.php" ]; then
    echo -e "${RED}[ERROR] File index.php tidak ditemukan di $SRC_DIR!${NC}"
    exit 1
fi

# ------------------------------------------------------------------------------
# 2. Configuration Setup
# ------------------------------------------------------------------------------
AUTO_ACCEPT=false
if [[ "$1" == "-y" || "$1" == "--yes" ]]; then
    AUTO_ACCEPT=true
fi

# Detect Server IP (instant via local network interface)
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(curl -s -m 2 https://api.ipify.org 2>/dev/null || echo "127.0.0.1")
fi

# Set default web root based on source dir
if [ "$SRC_DIR" = "/var/www/garudacbt" ]; then
    WEB_ROOT="/var/www/garudacbt"
else
    WEB_ROOT="/var/www/saduci_cbt"
fi

DB_NAME="saduci_cbt"
DB_USER="saduci_cbt"

# Generate random secure DB password instantly without blocking stdin
RANDOM_PASS=$(openssl rand -hex 8 2>/dev/null || date +%s%N 2>/dev/null | sha256sum | head -c 16)
if [ -z "$RANDOM_PASS" ]; then
    RANDOM_PASS="SaduciPass$(date +%s)"
fi
DB_PASS="$RANDOM_PASS"

if [ "$AUTO_ACCEPT" = false ]; then
    echo -e "${YELLOW}Silakan konfirmasi konfigurasi instalasi (Tekan ENTER untuk nilai default):${NC}"
    read -p "Domain atau IP Server [$SERVER_IP]: " INPUT_DOMAIN
    SERVER_DOMAIN=${INPUT_DOMAIN:-$SERVER_IP}

    read -p "Folder Web Root [$WEB_ROOT]: " INPUT_WEB_ROOT
    WEB_ROOT=${INPUT_WEB_ROOT:-$WEB_ROOT}

    read -p "Nama Database [$DB_NAME]: " INPUT_DB_NAME
    DB_NAME=${INPUT_DB_NAME:-$DB_NAME}

    read -p "User Database [$DB_USER]: " INPUT_DB_USER
    DB_USER=${INPUT_DB_USER:-$DB_USER}

    read -p "Password Database [$DB_PASS]: " INPUT_DB_PASS
    DB_PASS=${INPUT_DB_PASS:-$DB_PASS}

    read -p "Pasang SSL Let's Encrypt? (y/n) [n]: " INPUT_SSL
    INSTALL_SSL=${INPUT_SSL:-n}
else
    SERVER_DOMAIN="$SERVER_IP"
    INSTALL_SSL="n"
fi

echo -e "\n${GREEN}--> Menyiapkan instalasi dengan konfigurasi:${NC}"
echo -e "    Domain / IP     : ${CYAN}$SERVER_DOMAIN${NC}"
echo -e "    Web Root Path   : ${CYAN}$WEB_ROOT${NC}"
echo -e "    Database Name   : ${CYAN}$DB_NAME${NC}"
echo -e "    Database User   : ${CYAN}$DB_USER${NC}"
echo -e "    Database Pass   : ${CYAN}$DB_PASS${NC}"
echo ""

# ------------------------------------------------------------------------------
# 3. System Update & Dependencies
# ------------------------------------------------------------------------------
echo -e "${BLUE}[1/7] Memperbarui repositori paket Linux...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y software-properties-common curl wget git unzip lsb-release ca-certificates apt-transport-https

# ------------------------------------------------------------------------------
# 4. Install Apache, MariaDB, and PHP
# ------------------------------------------------------------------------------
echo -e "${BLUE}[2/7] Menginstall Apache2, MariaDB Server, dan Composer...${NC}"
apt-get install -y apache2 mariadb-server composer

# Setup PHP (Prefer PHP 7.4 or 8.1 for CodeIgniter 3 stability)
echo -e "${BLUE}[3/7] Menginstall PHP dan ekstensi yang dibutuhkan...${NC}"
PHP_INSTALLED=false

# Try installing PHP PPA if Ubuntu
if [ "$OS_NAME" = "ubuntu" ]; then
    add-apt-repository -y ppa:ondrej/php || true
    apt-get update -y
fi

# Attempt to install PHP 7.4, fallback to PHP 8.1, fallback to default distro PHP
if apt-get install -y php7.4 php7.4-cli php7.4-mysql php7.4-gd php7.4-mbstring php7.4-xml php7.4-curl php7.4-zip php7.4-json php7.4-intl libapache2-mod-php7.4; then
    PHP_VER="7.4"
    PHP_INSTALLED=true
elif apt-get install -y php8.1 php8.1-cli php8.1-mysql php8.1-gd php8.1-mbstring php8.1-xml php8.1-curl php8.1-zip php8.1-intl libapache2-mod-php8.1; then
    PHP_VER="8.1"
    PHP_INSTALLED=true
else
    # Fallback to system default PHP
    apt-get install -y php php-cli php-mysql php-gd php-mbstring php-xml php-curl php-zip php-intl libapache2-mod-php
    PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    PHP_INSTALLED=true
fi

echo -e "${GREEN}--> PHP versi $PHP_VER berhasil dipasang.${NC}"

# Tune PHP settings for High-Volume CBT Exam Environment
PHP_INI="/etc/php/$PHP_VER/apache2/php.ini"
if [ -f "$PHP_INI" ]; then
    echo -e "${BLUE}[*] Mengoptimalkan parameter php.ini untuk CBT...${NC}"
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 128M/" "$PHP_INI"
    sed -i "s/post_max_size = .*/post_max_size = 128M/" "$PHP_INI"
    sed -i "s/memory_limit = .*/memory_limit = 512M/" "$PHP_INI"
    sed -i "s/max_execution_time = .*/max_execution_time = 300/" "$PHP_INI"
    sed -i "s/max_input_time = .*/max_input_time = 300/" "$PHP_INI"
    
    # Ensure max_input_vars is high enough for large student exam answer submissions
    if grep -q "max_input_vars" "$PHP_INI"; then
        sed -i "s/.*max_input_vars = .*/max_input_vars = 10000/" "$PHP_INI"
    else
        echo "max_input_vars = 10000" >> "$PHP_INI"
    fi
    
    # Set timezone
    sed -i "s/;date.timezone =.*/date.timezone = Asia\/Jakarta/" "$PHP_INI"
fi

# ------------------------------------------------------------------------------
# 5. Database Configuration & Schema Import
# ------------------------------------------------------------------------------
echo -e "${BLUE}[4/7] Mengonfigurasi MariaDB & mengimpor database...${NC}"
systemctl start mariadb || systemctl start mysql
systemctl enable mariadb || systemctl enable mysql

# Create Database and User
mariadb -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mariadb -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mariadb -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';"
mariadb -e "FLUSH PRIVILEGES;"

# Import master.sql if available
SQL_FILE="$SRC_DIR/assets/app/db/master.sql"
if [ -f "$SQL_FILE" ]; then
    echo -e "--> Mengimpor skema awal dari master.sql..."
    mariadb "$DB_NAME" < "$SQL_FILE" || true
    echo -e "${GREEN}--> Skema database berhasil diimpor!${NC}"
else
    echo -e "${YELLOW}[!] File master.sql tidak ditemukan di $SQL_FILE, lewati impor.${NC}"
fi

# Ensure school setting is configured as SADUCI CBT
mariadb "$DB_NAME" -e "INSERT INTO \`setting\` (\`id_setting\`, \`kode_sekolah\`, \`sekolah\`, \`nama_aplikasi\`, \`alamat\`, \`desa\`, \`kecamatan\`, \`kota\`, \`provinsi\`, \`logo_kanan\`, \`logo_kiri\`, \`versi\`) VALUES (1, 'SADUCI', 'SMP NEGERI SATU ATAP 2 CIPATUJAH', 'SADUCI CBT', 'Cipatujah', 'Cipatujah', 'Cipatujah', 'Kab. Tasikmalaya', 'Jawa Barat', 'assets/img/saduci_logo.png', 'assets/img/saduci_logo.png', '1.5.3') ON DUPLICATE KEY UPDATE \`nama_aplikasi\` = 'SADUCI CBT', \`sekolah\` = 'SMP NEGERI SATU ATAP 2 CIPATUJAH', \`kota\` = 'Kab. Tasikmalaya', \`logo_kanan\` = 'assets/img/saduci_logo.png', \`logo_kiri\` = 'assets/img/saduci_logo.png';" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 6. Deploy Files to Web Root & Configure Permissions
# ------------------------------------------------------------------------------
echo -e "${BLUE}[5/7] Menyalin aplikasi ke $WEB_ROOT dan mengatur permission...${NC}"
mkdir -p "$WEB_ROOT"

if [ "$SRC_DIR" != "$WEB_ROOT" ]; then
    cp -r "$SRC_DIR"/* "$WEB_ROOT"/
    # Copy hidden files like .htaccess and .gitignore
    cp -a "$SRC_DIR"/.htaccess "$WEB_ROOT"/ 2>/dev/null || true
    cp -a "$SRC_DIR"/.gitignore "$WEB_ROOT"/ 2>/dev/null || true
fi

# Create required writable directories
mkdir -p "$WEB_ROOT/uploads"
mkdir -p "$WEB_ROOT/backups"
mkdir -p "$WEB_ROOT/application/logs"
mkdir -p "$WEB_ROOT/application/cache"

# Configure database.php automatically
DB_CONFIG_FILE="$WEB_ROOT/application/config/database.php"
if [ -f "$DB_CONFIG_FILE" ]; then
    echo -e "--> Mengonfigurasi credentials di application/config/database.php..."
    sed -i "s/'hostname' => getenv('DB_HOST') ? getenv('DB_HOST') : '.*'/'hostname' => getenv('DB_HOST') ? getenv('DB_HOST') : 'localhost'/" "$DB_CONFIG_FILE"
    sed -i "s/'username' => getenv('DB_USER') ? getenv('DB_USER') : '.*'/'username' => getenv('DB_USER') ? getenv('DB_USER') : '$DB_USER'/" "$DB_CONFIG_FILE"
    sed -i "s/'password' => getenv('DB_PASS') ? getenv('DB_PASS') : '.*'/'password' => getenv('DB_PASS') ? getenv('DB_PASS') : '$DB_PASS'/" "$DB_CONFIG_FILE"
    sed -i "s/'database' => getenv('DB_NAME') ? getenv('DB_NAME') : '.*'/'database' => getenv('DB_NAME') ? getenv('DB_NAME') : '$DB_NAME'/" "$DB_CONFIG_FILE"
fi

# Set proper ownership & permissions
chown -R www-data:www-data "$WEB_ROOT"
find "$WEB_ROOT" -type d -exec chmod 755 {} \;
find "$WEB_ROOT" -type f -exec chmod 644 {} \;
chmod -R 775 "$WEB_ROOT/uploads"
chmod -R 775 "$WEB_ROOT/backups"
chmod -R 775 "$WEB_ROOT/application/logs"
chmod -R 775 "$WEB_ROOT/application/cache"

# Install composer dependencies if composer.json exists
if [ -f "$WEB_ROOT/composer.json" ]; then
    echo -e "--> Menjalankan composer install untuk library Excel & PDF..."
    cd "$WEB_ROOT"
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction || true
    chown -R www-data:www-data "$WEB_ROOT/vendor" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 7. Configure Apache VirtualHost & Modules
# ------------------------------------------------------------------------------
echo -e "${BLUE}[6/7] Mengonfigurasi Apache VirtualHost...${NC}"
a2enmod rewrite headers expires ssl 2>/dev/null || true

VHOST_FILE="/etc/apache2/sites-available/saduci_cbt.conf"
cat <<EOF > "$VHOST_FILE"
<VirtualHost *:80>
    ServerName $SERVER_DOMAIN
    DocumentRoot $WEB_ROOT

    <Directory $WEB_ROOT>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/saduci_cbt_error.log
    CustomLog \${APACHE_LOG_DIR}/saduci_cbt_access.log combined
</VirtualHost>
EOF

# Enable site & disable default 000-default and legacy garudacbt
a2dissite 000-default.conf garudacbt.conf 2>/dev/null || true
a2ensite saduci_cbt.conf

# Restart Apache
systemctl restart apache2

# Allow Firewall if UFW is active
if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 443/tcp 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 8. Optional SSL via Certbot Let's Encrypt
# ------------------------------------------------------------------------------
if [[ "$INSTALL_SSL" =~ ^[Yy]$ && "$SERVER_DOMAIN" != "$SERVER_IP" && "$SERVER_DOMAIN" != "localhost" ]]; then
    echo -e "${BLUE}[7/7] Memasang sertifikat SSL Let's Encrypt...${NC}"
    apt-get install -y certbot python3-certbot-apache
    certbot --apache -d "$SERVER_DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email || true
else
    echo -e "${BLUE}[7/7] Melewati pemasangan SSL (bisa dipasang nanti dengan certbot).${NC}"
fi

# ------------------------------------------------------------------------------
# 9. Installation Complete Summary
# ------------------------------------------------------------------------------
echo -e "\n${GREEN}${BOLD}======================================================================${NC}"
echo -e "${GREEN}${BOLD}        INSTALASI SADUCI CBT BERHASIL DISELESAIKAN!                   ${NC}"
echo -e "${GREEN}${BOLD}             SMP NEGERI SATU ATAP 2 CIPATUJAH                         ${NC}"
echo -e "${GREEN}${BOLD}======================================================================${NC}"
echo ""
echo -e "  Akses Aplikasi   : ${CYAN}http://$SERVER_DOMAIN/${NC}"
echo -e "  Lokasi Web Root  : ${YELLOW}$WEB_ROOT${NC}"
echo -e "  Database Name    : ${YELLOW}$DB_NAME${NC}"
echo -e "  Database User    : ${YELLOW}$DB_USER${NC}"
echo -e "  Database Pass    : ${YELLOW}$DB_PASS${NC}"
echo ""
echo -e "  ${BOLD}Akun Login Default (Admin):${NC}"
echo -e "  Username         : ${CYAN}admin${NC}"
echo -e "  Password         : ${CYAN}admin${NC}"
echo ""
echo -e "  ${BOLD}Perintah Berguna:${NC}"
echo -e "  Restart Apache   : ${CYAN}sudo systemctl restart apache2${NC}"
echo -e "  Restart Database : ${CYAN}sudo systemctl restart mariadb${NC}"
echo -e "  Cek Log Error    : ${CYAN}sudo tail -f /var/log/apache2/saduci_cbt_error.log${NC}"
echo -e "${GREEN}======================================================================${NC}\n"

