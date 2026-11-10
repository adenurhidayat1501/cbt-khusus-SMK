<?php
error_reporting(0);
if (!defined('BASEPATH')) define('BASEPATH', TRUE);

$db_config_path = '../application/config/database.php';
$is_locked = false;

if (file_exists($db_config_path)) {
    include($db_config_path);
    if (isset($db['default']['database']) && !empty($db['default']['database'])) {
        $mysqli = @new mysqli($db['default']['hostname'], $db['default']['username'], $db['default']['password'], $db['default']['database']);
        if (!$mysqli->connect_errno) {
            $check = $mysqli->query("SHOW TABLES LIKE 'users'");
            if ($check && $check->num_rows > 0) {
                $is_locked = true;
            }
            if ($check) $check->close();
            $mysqli->close();
        }
    }
}

if ($is_locked && !isset($_POST['hostname']) && !isset($_GET['force'])) {
    die("ERROR: Installer terkunci. Aplikasi Necis CBT by Dado sudah terkonfigurasi. Hapus folder 'installer' dari server untuk alasan keamanan.");
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && $_POST) {

    require_once('includes/taskCoreClass.php');
    require_once('includes/databaseLibrary.php');

    $core = new Core();
    $database = new Database();

    $message = '';
    if ($core->checkEmpty($_POST) == true) {
        if ($database->create_database($_POST) == false) {
            $message = $core->show_message('error',
                "ERROR#001<br>Gagal terhubung ke MySQL atau gagal membuat database.<br>Pastikan MySQL (XAMPP/Laragon) sudah AKTIF dan username/password benar.");
        } else if ($database->create_tables($_POST) == false) {
            $message = $core->show_message('error',
                "ERROR#002<br>Gagal mengimpor tabel database master.sql.<br>Periksa hak akses user MySQL Anda.");
        } else if ($core->checkFile() == false) {
            $message = $core->show_message('error',
                "ERROR#003<br>File application/config/database.php tidak ditemukan.");
        } else if ($core->write_db_config($_POST) == false) {
            $message = $core->show_message('error',
                "ERROR#004<br>Gagal memperbarui file database.php.<br>Pastikan folder application/config/ dapat ditulis (writable).");
        }
    } else {
        $message = $core->show_message('error',
            "ERROR#005<br>Parameter tidak lengkap. Pastikan Host, Username, dan Nama Database telah diisi.");
    }

    echo $message;
}
