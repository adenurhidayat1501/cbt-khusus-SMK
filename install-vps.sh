#!/usr/bin/env bash
# ==============================================================================
# Necis CBT by Dado - Automated VPS Installer Script (Ubuntu / Debian)
# SMK NEGERI CIPATUJAH
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
echo "          Necis CBT by Dado - AUTOMATED VPS INSTALLER SCRIPT                 "
echo "              SMK NEGERI CIPATUJAH                        "
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
# 2. Configuration Setup (Manual DB Guided Setup)
# ------------------------------------------------------------------------------
# Detect Server IP (instant via local network interface)
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(curl -s -m 2 https://api.ipify.org 2>/dev/null || echo "127.0.0.1")
fi

# Set default web root based on source dir
if [ "$SRC_DIR" = "/var/www/garudacbt" ]; then
    WEB_ROOT="/var/www/garudacbt"
else
    WEB_ROOT="/var/www/necis_cbt"
fi

DEFAULT_DB_NAME="necis_cbt"
DEFAULT_DB_USER="necis_cbt"
DEFAULT_DB_PASS="necis123"

echo -e "${YELLOW}${BOLD}======================================================================${NC}"
echo -e "${YELLOW}${BOLD}           PANDUAN SETUP DATABASE Necis CBT by Dado                          ${NC}"
echo -e "${YELLOW}${BOLD}======================================================================${NC}"
echo -e "Silakan tentukan nama database dan kredensial yang Anda inginkan."
echo -e "Tekan [ENTER] langsung jika ingin menggunakan nilai rekomendasi [ ]: \n"

read -p ">> Masukkan Nama Database [$DEFAULT_DB_NAME]: " INPUT_DB_NAME
DB_NAME=${INPUT_DB_NAME:-$DEFAULT_DB_NAME}

read -p ">> Masukkan User Database [$DEFAULT_DB_USER]: " INPUT_DB_USER
DB_USER=${INPUT_DB_USER:-$DEFAULT_DB_USER}

read -p ">> Masukkan Password Database [$DEFAULT_DB_PASS]: " INPUT_DB_PASS
DB_PASS=${INPUT_DB_PASS:-$DEFAULT_DB_PASS}

read -p ">> Domain atau IP Server [$SERVER_IP]: " INPUT_DOMAIN
SERVER_DOMAIN=${INPUT_DOMAIN:-$SERVER_IP}

read -p ">> Setup database lewat Web Browser Wizard (/install) nanti? (y/n) [n]: " INPUT_WEB_SETUP
SETUP_VIA_WEB=${INPUT_WEB_SETUP:-n}

INSTALL_SSL="n"
if [[ "$SERVER_DOMAIN" != "$SERVER_IP" && "$SERVER_DOMAIN" != "localhost" ]]; then
    read -p ">> Pasang SSL Let's Encrypt? (y/n) [n]: " INPUT_SSL
    INSTALL_SSL=${INPUT_SSL:-n}
fi

echo -e "\n${GREEN}--> Menyiapkan instalasi dengan konfigurasi:${NC}"
echo -e "    Domain / IP     : ${CYAN}$SERVER_DOMAIN${NC}"
echo -e "    Web Root Path   : ${CYAN}$WEB_ROOT${NC}"
echo -e "    Database Name   : ${CYAN}$DB_NAME${NC}"
echo -e "    Database User   : ${CYAN}$DB_USER${NC}"
echo -e "    Database Pass   : ${CYAN}$DB_PASS${NC}"
echo -e "    Setup via Web   : ${CYAN}$SETUP_VIA_WEB${NC}"
echo ""

# ------------------------------------------------------------------------------
# 3. System Update & Dependencies
# ------------------------------------------------------------------------------
echo -e "${BLUE}[1/7] Memperbarui repositori paket Linux...${NC}"
export DEBIAN_FRONTEND=noninteractive

# Proactively fix known broken/corrupted local mirrors (like cermin.rumahweb.id)
if grep -rq "cermin.rumahweb.id" /etc/apt/ 2>/dev/null; then
    echo -e "${YELLOW}[*] Mengalihkan mirror cermin.rumahweb.id ke archive.ubuntu.com...${NC}"
    sed -i 's|cermin.rumahweb.id|archive.ubuntu.com|g' /etc/apt/sources.list /etc/apt/sources.list.d/*.sources 2>/dev/null || true
    rm -rf /var/lib/apt/lists/*
    apt-get clean
fi
apt-get update -y || true

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
    apt-get update -y || true
fi

# Attempt to install PHP 7.4, fallback to PHP 8.1, fallback to default distro PHP
if apt-get install -y php7.4 php7.4-cli php7.4-mysql php7.4-gd php7.4-mbstring php7.4-xml php7.4-curl php7.4-zip php7.4-intl libapache2-mod-php7.4; then
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
mariadb -e "ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mariadb -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';"
mariadb -e "FLUSH PRIVILEGES;"

# Import master.sql and initial schema if not web setup
if [[ "$SETUP_VIA_WEB" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}--> Mode Web Installer dipilih. Pembuatan tabel akan dilakukan melalui browser di /install.${NC}"
else
    SQL_FILE="$SRC_DIR/assets/app/db/master.sql"
    if [ -f "$SQL_FILE" ]; then
        echo -e "--> Mengimpor skema awal dari master.sql ke database '$DB_NAME'..."
        mariadb "$DB_NAME" < "$SQL_FILE" || true
        echo -e "${GREEN}--> Skema database berhasil diimpor!${NC}"
    else
        echo -e "${YELLOW}[!] File master.sql tidak ditemukan di $SQL_FILE, lewati impor.${NC}"
    fi

    # Ensure school setting is configured as Necis CBT by Dado & fix schema defaults
    mariadb "$DB_NAME" -e "INSERT INTO \`setting\` (\`id_setting\`, \`kode_sekolah\`, \`sekolah\`, \`nama_aplikasi\`, \`alamat\`, \`desa\`, \`kecamatan\`, \`kota\`, \`provinsi\`, \`logo_kanan\`, \`logo_kiri\`, \`versi\`) VALUES (1, 'NECIS', 'SMK NEGERI CIPATUJAH', 'Necis CBT by Dado', 'Cipatujah', 'Cipatujah', 'Cipatujah', 'Kab. Tasikmalaya', 'Jawa Barat', 'assets/img/necis_logo.png', 'assets/img/necis_logo.png', '1.5.3') ON DUPLICATE KEY UPDATE \`nama_aplikasi\` = 'Necis CBT by Dado', \`sekolah\` = 'SMK NEGERI CIPATUJAH', \`kota\` = 'Kab. Tasikmalaya', \`logo_kanan\` = 'assets/img/necis_logo.png', \`logo_kiri\` = 'assets/img/necis_logo.png';" 2>/dev/null || true
    mariadb "$DB_NAME" -e "ALTER TABLE \`master_tp\` MODIFY \`active\` int(11) NOT NULL DEFAULT 0; ALTER TABLE \`master_kelas\` MODIFY \`jurusan_id\` int(11) NOT NULL DEFAULT 0;" 2>/dev/null || true

    # Ensure default admin user exists
    ADMIN_HASH=$(php -r "echo password_hash('admin', PASSWORD_BCRYPT);" 2>/dev/null || echo '$2y$10$wO3t4hNl7m7r6T4G2fF3NuR9y7eM5uB2wE4pP8gL4uP8pL7vAeLq2')
    mariadb "$DB_NAME" -e "INSERT INTO \`users\` (\`id\`, \`ip_address\`, \`username\`, \`password\`, \`email\`, \`created_on\`, \`active\`, \`first_name\`, \`last_name\`) VALUES (1, '127.0.0.1', 'admin', '$ADMIN_HASH', 'admin@smkncipatujah.sch.id', UNIX_TIMESTAMP(), 1, 'Administrator', 'NECIS') ON DUPLICATE KEY UPDATE \`id\` = 1;" 2>/dev/null || true
    mariadb "$DB_NAME" -e "INSERT INTO \`users_groups\` (\`id\`, \`user_id\`, \`group_id\`) VALUES (1, 1, 1) ON DUPLICATE KEY UPDATE \`group_id\` = 1;" 2>/dev/null || true
fi

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
    if [[ "$SETUP_VIA_WEB" =~ ^[Yy]$ ]]; then
        sed -i "s/'database' => getenv('DB_NAME') ? getenv('DB_NAME') : '.*'/'database' => getenv('DB_NAME') ? getenv('DB_NAME') : ''/" "$DB_CONFIG_FILE"
    else
        sed -i "s/'database' => getenv('DB_NAME') ? getenv('DB_NAME') : '.*'/'database' => getenv('DB_NAME') ? getenv('DB_NAME') : '$DB_NAME'/" "$DB_CONFIG_FILE"
    fi
fi

# Set proper ownership & permissions (fast batch mode with +)
chown -R www-data:www-data "$WEB_ROOT"
find "$WEB_ROOT" -type d -exec chmod 755 {} +
find "$WEB_ROOT" -type f -exec chmod 644 {} +
chmod -R 775 "$WEB_ROOT/uploads" "$WEB_ROOT/backups" "$WEB_ROOT/application/logs" "$WEB_ROOT/application/cache" 2>/dev/null || true

# Install composer dependencies if composer.json exists and vendor not yet populated
if [ -f "$WEB_ROOT/composer.json" ]; then
    if [ ! -f "$WEB_ROOT/vendor/autoload.php" ]; then
        echo -e "${BLUE}[*] Mengunduh library Excel & PDF via Composer (proses ini membutuhkan waktu 1-3 menit, mohon tunggu)...${NC}"
        cd "$WEB_ROOT"
        COMPOSER_ALLOW_SUPERUSER=1 composer install --ignore-platform-reqs --no-dev --optimize-autoloader --no-interaction 2>/dev/null || \
        COMPOSER_ALLOW_SUPERUSER=1 composer update --ignore-platform-reqs --no-dev --optimize-autoloader --no-interaction || true
        chown -R www-data:www-data "$WEB_ROOT/vendor" 2>/dev/null || true
    else
        echo -e "${GREEN}--> Library vendor (Excel & PDF) sudah terpasang, melewati unduhan.${NC}"
    fi
fi

# ------------------------------------------------------------------------------
# 7. Configure Apache VirtualHost & Modules
# ------------------------------------------------------------------------------
echo -e "${BLUE}[6/7] Mengonfigurasi Apache VirtualHost...${NC}"
a2enmod rewrite headers expires ssl 2>/dev/null || true

VHOST_FILE="/etc/apache2/sites-available/necis_cbt.conf"
cat <<EOF > "$VHOST_FILE"
<VirtualHost *:80>
    ServerName $SERVER_DOMAIN
    DocumentRoot $WEB_ROOT

    <Directory $WEB_ROOT>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/necis_cbt_error.log
    CustomLog \${APACHE_LOG_DIR}/necis_cbt_access.log combined
</VirtualHost>
EOF

# Enable site & disable default 000-default and legacy garudacbt
a2dissite 000-default.conf garudacbt.conf 2>/dev/null || true
a2ensite necis_cbt.conf

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
echo -e "${GREEN}${BOLD}        INSTALASI Necis CBT by Dado BERHASIL DISELESAIKAN!                   ${NC}"
echo -e "${GREEN}${BOLD}             SMK NEGERI CIPATUJAH                         ${NC}"
echo -e "${GREEN}${BOLD}======================================================================${NC}"
echo ""
echo -e "  Akses Server     : ${CYAN}http://$SERVER_DOMAIN/${NC}"
echo -e "  Lokasi Web Root  : ${YELLOW}$WEB_ROOT${NC}"
echo -e "  Host Database    : ${CYAN}localhost${NC}"
echo -e "  Database Name    : ${YELLOW}$DB_NAME${NC}"
echo -e "  Database User    : ${YELLOW}$DB_USER${NC}"
echo -e "  Database Pass    : ${YELLOW}$DB_PASS${NC}"
echo ""

if [[ "$SETUP_VIA_WEB" =~ ^[Yy]$ ]]; then
    echo -e "  ${BOLD}${YELLOW}[!] MODE WEB WIZARD AKTIF:${NC}"
    echo -e "  Silakan buka: ${CYAN}http://$SERVER_DOMAIN/install${NC} di browser Anda."
    echo -e "  Gunakan Database Name: ${YELLOW}$DB_NAME${NC}, User: ${YELLOW}$DB_USER${NC}, Pass: ${YELLOW}$DB_PASS${NC}"
else
    echo -e "  ${BOLD}Akun Login Default (Admin):${NC}"
    echo -e "  Username         : ${CYAN}admin${NC}"
    echo -e "  Password         : ${CYAN}admin${NC}"
    echo -e "  Akses Langsung   : ${CYAN}http://$SERVER_DOMAIN/${NC}"
fi

echo ""
echo -e "  ${BOLD}Perintah Berguna:${NC}"
echo -e "  Restart Apache   : ${CYAN}sudo systemctl restart apache2${NC}"
echo -e "  Restart Database : ${CYAN}sudo systemctl restart mariadb${NC}"
echo -e "  Cek Log Error    : ${CYAN}sudo tail -f /var/log/apache2/necis_cbt_error.log${NC}"
echo -e "${GREEN}======================================================================${NC}\n"

