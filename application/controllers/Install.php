<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Install extends CI_Controller {

    function __construct(){
        parent::__construct();

        include APPPATH . 'config/database.php';
        if ($db['default']['database'] != '') {
            $this->load->database();
            $this->load->dbforge();
        }

        $this->load->model('Install_model', 'install');
        $this->load->model('Dashboard_model', 'dashboard');

        if ($this->install->check_installer() == '0') {
            if (!$this->ion_auth->logged_in() || !$this->ion_auth->is_admin()) {
                redirect('auth');
            }
        }
    }

    public function output_json($data, $encode = true){
        if($encode) $data = json_encode($data);
        $this->output->set_content_type('application/json')->set_output($data);
    }

    public function index(){
        $res = $this->install->check_installer();
        if ($res == '0') {
            redirect('update');
        } else {
            if ($res == '2') {
                $data['msg'] = 'sebagian tabel belum dibuat';
            } elseif ($res == '3') {
                $data['msg'] = 'belum ada administrator';
            } else {
                $data['msg'] = 'belum ada data sekolah';
            }

            $data = $this->getSaved();
            $data->error = $res;
            $this->load->view('install/header', ['data'=>$data]);
            $this->load->view('install/step');
            $this->load->view('install/footer');
        }
    }

    function getSaved() {
        include APPPATH . 'config/database.php';
        $database = $db['default']['database'];
        $data['hostname'] = $db['default']['hostname'];
        $data['username'] = $db['default']['username'];
        $data['password'] = $db['default']['password'];
        $data['database'] = $database;

        $data['nama_admin'] = '';
        $data['user_admin'] = '';
        $data['pass_admin'] = '';

        $data['aplikasi'] = '';
        $data['sekolah'] = '';
        $data['jenjang'] = '';
        $data['satuan'] = '';
        $data['kepsek'] = '';
        $data['alamat'] = '';
        $data['desa'] = '';
        $data['kec'] = '';
        $data['kota'] = '';
        $data['prov'] = '';

        $current_page = 2;
        if ($this->db->table_exists('users')) {
            $admin = $this->db->get('users')->row();
            if ($admin != null) {
                $data['nama_admin'] = $admin->first_name . ' ' . $admin->last_name;
                $data['user_admin'] = $admin->username;
                $data['pass_admin'] = '';
            }

            $setting = $this->dashboard->getSetting();
            if ($setting != null) {
                $data['aplikasi'] = $setting->nama_aplikasi;
                $data['sekolah'] = $setting->sekolah;
                $data['jenjang'] = $setting->jenjang;
                $data['satuan'] = $setting->satuan_pendidikan;
                $data['kepsek'] = $setting->kepsek;
                $data['alamat'] = $setting->alamat;
                $data['desa'] = $setting->desa;
                $data['kec'] = $setting->kecamatan;
                $data['kota'] = $setting->kota;
                $data['prov'] = $setting->provinsi;
            }
            $current_page = $admin == null ? 2 : ($setting == null ? 3 : 4);
        } else {
            $current_page = 2;
            $data['msg'] = 'Table `users` belum dibuat';
        }
        $data['current_page'] = $current_page;
        return json_decode(json_encode($data));
    }

    public function steps() {
        $data = $this->getSaved();
        $this->load->view('install/header', ['data'=>$data]);
        $this->load->view('install/step');
        $this->load->view('install/footer');
    }

    public function checkDatabase() {
        $hostname = $this->input->post('hostname', true);
        $hostuser = $this->input->post('hostuser', true);
        $hostpass = $this->input->post('hostpass', true);
        $database = $this->input->post('database', true);
        //buat database
        if ($this->validate_host($hostname, $hostuser, $database)) {
            $template_path = './assets/app/db/database.php';
            $output_path = APPPATH . 'config/database.php';

            $database_file = file_get_contents($template_path);

            $new = str_replace("%HOSTNAME%", $hostname, $database_file);
            $new = str_replace("%USERNAME%", $hostuser, $new);
            $new = str_replace("%PASSWORD%", $hostpass, $new);
            $new = str_replace("%DATABASE%", $database, $new);

            $handle = fopen($output_path, 'w+');

            @chmod($output_path, 0777);

            if (is_writable($output_path)) {
                if (fwrite($handle, $new)) {
                    $data['host'] = true;
                    $data['host_msg'] = 'behasil';

                    $data['database'] = $this->create_database($hostname, $hostuser, $hostpass, $database);
                    $data['table'] = $this->create_tables($hostname, $hostuser, $hostpass, $database);
                    $data['host'] = true;
                    $data['host_msg'] = 'sukses';
                    $data['database'] = true;
                } else {
                    $data['host'] = false;
                    $data['host_msg'] = 'gagal membuat nama database';
                }
            } else {
                $data['host'] = false;
                $data['host_msg'] = 'tidak ada akses ke file database.php, pastikan permission sudah dizinkan';
            }
        } else {
            $data['host'] = false;
            $data['host_msg'] = 'tidak boleh ada yang kosong';
        }
        $this->output_json($data);
    }

    public function createDb() {
        $page = $this->input->post('page', true);
        if ($page == '0') {
            $hostname = $this->input->post('hostname', true);
            $hostuser = $this->input->post('hostuser', true);
            $hostpass = $this->input->post('hostpass', true);
            $database = $this->input->post('database', true);

            $data['table'] = $this->create_tables($hostname, $hostuser, $hostpass, $database);
            $data['host'] = true;
            $data['host_msg'] = 'sukses';
            $data['database'] = true;
        } else {
            $data['host'] = true;
            $data['host_msg'] = 'step salah';
            $data['database'] = false;
            $data['table'] = false;
        }
        $this->output_json($data);
    }

    function validate_host($host, $usr, $db){
        return !empty($host) && !empty($usr) && !empty($db);
    }

    function create_database($hostname, $hostuser, $hostpass, $database) {
        $mysqli = new mysqli($hostname, $hostuser, $hostpass, '');
        if(mysqli_connect_errno()) return false;
        $mysqli->query("CREATE DATABASE IF NOT EXISTS ".$database);
        $mysqli->close();
        return true;
    }

    function create_tables($hostname, $hostuser, $hostpass, $database){
        $mysqli = new mysqli($hostname,$hostuser,$hostpass,$database);
        if(mysqli_connect_errno()) return false;

        $query = file_get_contents('./assets/app/db/master.sql');
        $mysqli->multi_query($query);
        $mysqli->close();

        return true;
    }

    public function createSetting(){
        try {
            $nama_aplikasi = $this->input->post('nama_aplikasi', true);
            $sekolah = $this->input->post('nama_sekolah', true);
            $jenjang = $this->input->post('jenjang', true);
            $satuan_pendidikan = $this->input->post('satuan_pendidikan', true);
            $kepsek = $this->input->post('kepsek', true);
            $alamat = $this->input->post('alamat', true);
            $kota = $this->input->post('kota', true);
            $kec = $this->input->post('kec', true);
            $desa = $this->input->post('desa', true);
            $tlp = $this->input->post('tlp', true);

            $insert = [
                'id_setting' => 1,
                'sekolah' => $sekolah,
                'jenjang' => $jenjang,
                'satuan_pendidikan' => $satuan_pendidikan,
                'alamat' => $alamat,
                'desa' => $desa,
                'kota' => $kota,
                'kecamatan' => $kec,
                'telp' => $tlp,
                'kepsek' => $kepsek,
                'nama_aplikasi' => $nama_aplikasi,
            ];

            if ($this->db->where('id_setting', 1)->get('setting')->row()) {
                $data['insert'] = $this->db->update('setting', $insert, ['id_setting' => 1]);
            } else {
                $data['insert'] = $this->db->insert('setting', $insert);
            }

            $data['saved'] = $this->getSaved();
            $this->output_json($data);
        } catch (\Throwable $e) {
            $this->output_json(['insert' => false, 'message' => $e->getMessage()]);
        }
    }

    public function createAdmin() {
        try {
            $nama = $this->input->post('nama_lengkap', true);
            $username = $this->input->post('username', true);
            $password = $this->input->post('password', true);

            $namaAdmin = explode(' ', trim($nama ?? ''));
            $first_name = $namaAdmin[0] ?? 'Admin';
            $last_name = count($namaAdmin) > 1 ? end($namaAdmin) : '';
            $additional_data = [
                'first_name'	=> $first_name,
                'last_name'		=> $last_name
            ];
            $group = array('1');
            $clean_name = preg_replace('/[^a-zA-Z0-9]/', '', strtolower($nama ?? 'admin'));
            $email = ($clean_name ?: 'admin') . '@admin.com';

            $existing = $this->db->where('username', $username)->get('users')->row();
            if ($existing) {
                $update_user = [
                    'password' => password_hash($password, PASSWORD_BCRYPT),
                    'first_name' => $first_name,
                    'last_name' => $last_name,
                    'email' => $email,
                    'active' => 1
                ];
                $create = $this->db->update('users', $update_user, ['id' => $existing->id]);
                $this->db->replace('users_groups', ['user_id' => $existing->id, 'group_id' => 1]);
            } else {
                $create = $this->ion_auth->register($username, $password, $email, $additional_data, $group);
            }

            $data['admin'] = (bool)$create;
            $this->output_json($data);
        } catch (\Throwable $e) {
            $this->output_json(['admin' => false, 'message' => $e->getMessage()]);
        }
    }

    public function createApp() {
        try {
            $nama = $this->input->post('nama_lengkap', true);
            $username = $this->input->post('username', true);
            $password = $this->input->post('password', true);

            $nama_aplikasi = $this->input->post('nama_aplikasi', true);
            $sekolah = $this->input->post('nama_sekolah', true);
            $jenjang = $this->input->post('jenjang', true);
            $satuan_pendidikan = $this->input->post('satuan', true);
            $kepsek = $this->input->post('kepsek', true);
            $alamat = $this->input->post('alamat', true);
            $kota = $this->input->post('kota', true);
            $kec = $this->input->post('kec', true);
            $desa = $this->input->post('desa', true);
            $prov = $this->input->post('prov', true);

            $insert = [
                'id_setting' => 1,
                'sekolah' => $sekolah,
                'jenjang' => $jenjang,
                'satuan_pendidikan' => $satuan_pendidikan,
                'alamat' => $alamat,
                'desa' => $desa,
                'kota' => $kota,
                'kecamatan' => $kec,
                'provinsi' => $prov,
                'kepsek' => $kepsek,
                'nama_aplikasi' => $nama_aplikasi,
            ];

            // Update setting if id 1 already exists, else insert
            if ($this->db->where('id_setting', 1)->get('setting')->row()) {
                $data['insert'] = $this->db->update('setting', $insert, ['id_setting' => 1]);
            } else {
                $data['insert'] = $this->db->insert('setting', $insert);
            }

            $namaAdmin = explode(' ', trim($nama ?? ''));
            $first_name = $namaAdmin[0] ?? 'Admin';
            $last_name = count($namaAdmin) > 1 ? end($namaAdmin) : '';
            $additional_data = [
                'first_name'	=> $first_name,
                'last_name'		=> $last_name
            ];
            $group = array('1');
            $clean_name = preg_replace('/[^a-zA-Z0-9]/', '', strtolower($nama ?? 'admin'));
            $email = ($clean_name ?: 'admin') . '@admin.com';

            $existing = $this->db->where('username', $username)->get('users')->row();
            if ($existing) {
                $update_user = [
                    'password' => password_hash($password, PASSWORD_BCRYPT),
                    'first_name' => $first_name,
                    'last_name' => $last_name,
                    'email' => $email,
                    'active' => 1
                ];
                $create = $this->db->update('users', $update_user, ['id' => $existing->id]);
                $this->db->replace('users_groups', ['user_id' => $existing->id, 'group_id' => 1]);
            } else {
                $create = $this->ion_auth->register($username, $password, $email, $additional_data, $group);
            }

            $data['admin'] = (bool)$create;
            $data['insert'] = (bool)$data['insert'];
            $this->output_json($data);
        } catch (\Throwable $e) {
            $this->output_json(['admin' => false, 'insert' => false, 'message' => $e->getMessage()]);
        }
    }

    /*
    function checkTable($table) {
        $data = $db['default'];
        $mysqli = new mysqli($data['hostname'], $data['username'], $data['password'], $data['database']);
        $sql = "SELECT count(*) FROM information_schema.TABLES WHERE (TABLE_SCHEMA = '"
            .$data['database']."') AND (TABLE_NAME = '".$table."');";
        $result = $mysqli->query($sql)->num_rows;
        $mysqli->close();
        return $result;
    }
    */
}
