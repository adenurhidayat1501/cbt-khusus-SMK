# SADUCI CBT - SMP Negeri Satu Atap 2 Cipatujah

[![PHP Version](https://img.shields.io/badge/PHP-7.4%20%7C%208.1-blue.svg)](https://www.php.net/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](license.txt)
[![Security](https://img.shields.io/badge/Security-Hardened%20%26%20Patched-brightgreen.svg)]()
[![UI/UX](https://img.shields.io/badge/UI%2FUX-ANBK%20Standard%202024--2026-blueviolet.svg)]()

Aplikasi **SADUCI CBT (SMP Negeri Satu Atap 2 Cipatujah, Kab. Tasikmalaya)** berbasis Computer Based Test (CBT) yang telah dimodernisasi dengan antarmuka elegan berstandar **ANBK**, identitas sekolah lengkap, patch keamanan menyeluruh, serta skrip otomatisasi instalasi pada server VPS (Ubuntu/Debian) dan container Docker.

---

## ✨ Fitur Unggulan

1. **Antarmuka Modern (UI/UX 2024–2026)**
   - **Identitas SADUCI CBT**: Dilengkapi logo resmi SMP Negeri Satu Atap 2 Cipatujah, badge institusi, dan favicon seragam.
   - **ANBK Exam Interface**: Tampilan ujian siswa berstandar Asesmen Nasional dengan kartu pilihan interaktif (A, B, C, D, E), indikator sisa waktu digital, dan dok navigasi responsif.
   - **Glassmorphic Login**: Halaman login modern dengan efek kaca melayang (*frosted glass*), ikon interaktif, dan *show/hide password toggle*.
   - **Deep Slate Dashboard**: Sidebar dan navbar dashboard Admin & Guru bertema *Slate 900* (`#0f172a`), ramah di mata, serta dilengkapi widget statistik modern.
2. **Keamanan Sistem yang Diperketat (*Hardened Security*)**
   - Perlindungan anti-bocor kunci jawaban pada API ujian siswa.
   - Sanitasi upload file dengan whitelist ekstensi ketat & perisai `.htaccess` anti eksekusi PHP pada folder `uploads/` dan `backups/`.
   - Pencegahan celah *path traversal* pada penghapusan berkas database dan foto.
   - Pengamanan installer dan update route dari akses tanpa otentikasi.
3. **Penyebaran Otomatis di VPS & Cloud**
   - Skrip `install-vps.sh` untuk instalasi mandiri Apache, MariaDB, PHP, ekstensi, permissions, VirtualHost, dan database dalam 1 perintah.
   - Dukungan `docker-compose.yml` untuk instalasi berbasis container.

---

## 🚀 Cara Upload ke GitHub (Dari Komputer Anda)

### Opsi A: Menggunakan Script Otomatis (Windows)
1. Buka folder proyek ini di Windows Explorer.
2. Dobel-klik file **`push-to-github.bat`**.
3. Masukkan URL repository GitHub: `https://github.com/adenurhidayat1501/cbt-sekolah.git`.
4. Script akan menginisialisasi Git, menambahkan berkas, membuat commit, dan mengunggah ke GitHub secara otomatis.

---

### Opsi B: Menggunakan Perintah Git Manual
Buka Command Prompt (CMD), PowerShell, atau Git Bash di dalam folder proyek, lalu jalankan:

```bash
# 1. Inisialisasi Git repository
git init

# 2. Tambahkan semua berkas ke staging
git add .

# 3. Buat commit pertama
git commit -m "SADUCI CBT - SMP Negeri Satu Atap 2 Cipatujah"

# 4. Atur branch utama ke 'main'
git branch -M main

# 5. Hubungkan dengan remote repository GitHub Anda
git remote add origin https://github.com/adenurhidayat1501/cbt-sekolah.git

# 6. Push source code ke GitHub
git push -u origin main
```

---

## 🛠️ Cara Install di VPS (Paling Gampang & Otomatis)

Setelah proyek berada di GitHub, Anda dapat memasangnya di VPS Linux (Ubuntu 20.04 / 22.04 / 24.04 atau Debian 11 / 12) dengan langkah mudah berikut:

### 🌟 Auto-Installer Script (Sangat Direkomendasikan)

Cukup login ke VPS Anda via SSH (sebagai `root`), lalu jalankan:

```bash
# 1. Clone repository dari GitHub
git clone https://github.com/adenurhidayat1501/cbt-sekolah.git /var/www/saduci_cbt

# 2. Masuk ke direktori
cd /var/www/saduci_cbt

# 3. Jalankan skrip instalasi otomatis (tambahkan -y untuk otomatis tanpa prompt)
sudo bash install-vps.sh -y
```

> *Catatan: Jika sudah terlanjur di-clone ke `/var/www/garudacbt`, jalankan:*
> ```bash
> cd /var/www/garudacbt && git pull && sudo bash install-vps.sh -y
> ```

> **Apa yang dikerjakan otomatis oleh skrip ini?**
> - Mengupdate sistem dan memasang Apache2, MariaDB Server, PHP, dan Composer.
> - Memasang seluruh ekstensi PHP yang dibutuhkan (`mysqli`, `gd`, `zip`, `mbstring`, `xml`, `curl`, `json`, `intl`).
> - Membuat database `saduci_cbt` dan user MariaDB dengan password acak yang aman.
> - Mengimpor skema tabel dan inisialisasi identitas SMP Negeri Satu Atap 2 Cipatujah.
> - Mengatur permission folder (`uploads/`, `backups/`, `logs/`).
> - Mengaktifkan `mod_rewrite` dan membuat VirtualHost Apache (`saduci_cbt.conf`).
> - Mengoptimalkan parameter `php.ini` (`upload_max_filesize = 128M`, `memory_limit = 512M`, `max_input_vars = 10000`).
> - Opsi pemasangan gratis sertifikat SSL Let's Encrypt jika menggunakan domain.

---

### 🐳 METODE 2: Menggunakan Docker & Docker Compose

Jika VPS Anda sudah terpasang Docker:

```bash
# 1. Clone repository
git clone https://github.com/adenurhidayat1501/cbt-sekolah.git saduci_cbt
cd saduci_cbt

# 2. Jalankan container di background
docker-compose up -d
```

Aplikasi langsung dapat diakses di `http://IP_SERVER_ANDA/`.

---

## 🔑 Informasi Login Default

Setelah instalasi selesai, Anda dapat langsung login sebagai Administrator:

| Parameter | Detail |
|:---|:---|
| **URL Akses** | `http://IP_SERVER/` atau `https://domain-anda.com/` |
| **Username Admin** | `admin` |
| **Password Admin** | `admin` |

> [!IMPORTANT]
> Segera ganti password default admin setelah login pertama kali melalui menu **Pengaturan > User Management > Administrator**.

---

## 📁 Struktur Berkas Penting

```
├── application/           # Logika aplikasi CodeIgniter 3 (Controllers, Models, Views)
│   ├── config/            # Konfigurasi database.php, config.php, routes.php
│   └── views/             # Template UI modern (Login, Siswa CBT, AdminLTE)
├── assets/                # Aset statis CSS, JS, Gambar, Font
│   ├── app/css/
│   │   └── modern-cbt.css # Core Design System Modern SADUCI CBT
│   ├── app/db/
│   │   └── master.sql     # Skema awal database & inisialisasi SADUCI CBT
│   └── img/
│       └── saduci_logo.png# Logo resmi SMPN Satu Atap 2 Cipatujah
├── backups/               # Direktori cadangan database (terlindungi .htaccess)
├── uploads/               # Direktori upload media & foto (terlindungi .htaccess)
├── install-vps.sh         # Script otomatis instalasi VPS Linux
├── push-to-github.bat     # Helper upload ke GitHub untuk Windows
├── push-to-github.sh      # Helper upload ke GitHub untuk Linux/macOS
├── Dockerfile             # Definisi container image PHP Apache
├── docker-compose.yml     # Konfigurasi container App + MariaDB
└── .gitignore             # Standar filter berkas Git
```

---

## 🛡️ Catatan Perawatan & Keamanan Server

- **Restart Web Server**: `sudo systemctl restart apache2`
- **Restart Database**: `sudo systemctl restart mariadb`
- **Cek Log Error**: `sudo tail -f /var/log/apache2/saduci_cbt_error.log`
- **Backup Manual**: Jalankan backup database berkala melalui menu admin atau via CLI:
  ```bash
  mysqldump -u saduci_cbt -p saduci_cbt > backup_$(date +%F).sql
  ```
