<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Datakelas extends CI_Controller {

	public function __construct() {
		parent::__construct();
		if (!$this->ion_auth->logged_in()) {
			redirect('auth');
		} else if (!$this->ion_auth->is_admin()) {
			show_error('Hanya Administrator yang diberi hak untuk mengakses halaman ini, <a href="' . base_url('dashboard') . '">Kembali ke menu awal</a>', 403, 'Akses Terlarang');
		}
		$this->load->library(['datatables', 'form_validation']); // Load Library Ignited-Datatables
		$this->load->model('Kelas_model', 'kelas');
		$this->load->model('Dashboard_model', 'dashboard');
		$this->load->model('Master_model', 'master');
        $this->load->model('Dropdown_model', 'dropdown');
        $this->load->model('Rapor_model', 'rapor');
		$this->form_validation->set_error_delimiters('', '');
	}

	public function output_json($data, $encode = true) {
		if ($encode) $data = json_encode($data);
		$this->output->set_content_type('application/json')->set_output($data);
	}

	public function index() {
        $user = $this->ion_auth->user()->row();
        $setting = $this->dashboard->getSetting();
        $data = [
            'user' => $user,
			'judul' => 'Kelas',
			'subjudul' => 'Data Kelas',
            'setting'		=> $setting
		];

		$tp = $this->dashboard->getTahunActive();
		$smt = $this->dashboard->getSemesterActive();

		$data['tp'] = $this->dashboard->getTahun();
		$data['tp_active'] = $tp;
		$data['smt'] = $this->dashboard->getSemester();
		$data['smt_active'] = $smt;
        $data['profile'] = $this->dashboard->getProfileAdmin($user->id);

        $chek = $this->kelas->count_all();
        $kelas = [];
        $kelas_lama = [];
        if ($chek > 0) {
            $kelas = $this->kelas->getKelasList($tp->id_tp, $smt->id_smt);
            $kelas_lama = $this->kelas->getKelasList(($tp->id_tp)-1, '2');
        }
		$data['kelas'] = $kelas;
        $data['kelas_lama'] = $kelas_lama;

		$data['jurusan'] = $this->kelas->get_jurusan();
        $data['level'] = $this->kelas->getLevel($setting->jenjang);
		$data['guru'] = $this->kelas->get_guru();
		$data['siswa'] = $this->kelas->getAllSiswa($tp->id_tp, $smt->id_smt);

		$this->load->view('_templates/dashboard/_header', $data);
		$this->load->view('master/kelas/data');
		$this->load->view('_templates/dashboard/_footer');
	}

    public function detail($id) {
        $user = $this->ion_auth->user()->row();
        $setting = $this->dashboard->getSetting();
        $data = [
            'user' => $user,
            'judul' => 'Detail Kelas',
            'subjudul' => 'Detail Kelas',
            'setting'		=> $setting
        ];
        $tp = $this->dashboard->getTahunActive();
        $smt = $this->dashboard->getSemesterActive();

        $data['tp'] = $this->dashboard->getTahun();
        $data['tp_active'] = $tp;
        $data['smt'] = $this->dashboard->getSemester();
        $data['smt_active'] = $smt;

        $data['profile'] = $this->dashboard->getProfileAdmin($user->id);
        $data['kelas'] = $this->kelas->get_one($id);
        $data['jurusan'] = $this->kelas->get_jurusan();
        $data['level'] = $this->kelas->getLevel($setting->jenjang);
        $data['guru'] = $this->kelas->get_guru();
        $data['siswas'] = $this->kelas->get_siswa_kelas($id, $tp->id_tp, $smt->id_smt);
        $struktur = $this->kelas->getStrukturKelas($id);
        if ($struktur==null) {
            $data['struktur'] = json_decode(json_encode($this->kelas->dummyStruktur()));
        } else {
            $data['struktur'] = $struktur;
        }

        $this->load->view('_templates/dashboard/_header', $data);
        $this->load->view('master/kelas/detail');
        $this->load->view('_templates/dashboard/_footer');
    }

	public function add() {
        $user = $this->ion_auth->user()->row();
        $setting = $this->dashboard->getSetting();
        $data = [
            'user' => $user,
			'judul' => 'Kelas',
			'subjudul' => 'Tambah Kelas',
            'setting'		=> $setting
		];

		$tp = $this->dashboard->getTahunActive();
		$smt = $this->dashboard->getSemesterActive();

		$data['tp'] = $this->dashboard->getTahun();
		$data['tp_active'] = $tp;
		$data['smt'] = $this->dashboard->getSemester();
		$data['smt_active'] = $smt;
        $data['profile'] = $this->dashboard->getProfileAdmin($user->id);

		$data['kelas'] = json_decode(json_encode($this->kelas->dummy()));
		$data['jurusan'] = $this->kelas->get_jurusan();
        $data['level'] = $this->kelas->getLevel($setting->jenjang);
		$data['guru'] = $this->kelas->get_guru();
		$siswa = $this->kelas->getAllSiswa($tp->id_tp, $smt->id_smt);
		$data['siswa'] = $siswa;
		$data['siswakelas'] = array();

		$this->load->view('_templates/dashboard/_header', $data);
		$this->load->view('master/kelas/add');
		$this->load->view('_templates/dashboard/_footer');
	}

	public function edit($id = '') {
        $user = $this->ion_auth->user()->row();
        $setting = $this->dashboard->getSetting();
        $data = [
            'user' => $user,
			'judul' => 'Kelas',
			'subjudul' => 'Edit Kelas',
            'setting'		=> $setting
		];
		$tp = $this->dashboard->getTahunActive();
		$smt = $this->dashboard->getSemesterActive();

		$data['tp'] = $this->dashboard->getTahun();
		$data['tp_active'] = $tp;
		$data['smt'] = $this->dashboard->getSemester();
		$data['smt_active'] = $smt;

        $data['profile'] = $this->dashboard->getProfileAdmin($user->id);
        $data['id_kelas'] = $id;
        $data['kelas'] = $this->kelas->get_one($id);
		$data['jurusan'] = $this->kelas->get_jurusan();
        $data['level'] = $this->kelas->getLevel($setting->jenjang);
		$data['guru'] = $this->kelas->getWaliKelas($tp->id_tp, $smt->id_smt);
		$data['siswa'] = $this->kelas->getAllSiswa($tp->id_tp, $smt->id_smt);
		$data['siswakelas'] = $this->kelas->get_siswa_kelas($id, $tp->id_tp, $smt->id_smt);

		$this->load->view('_templates/dashboard/_header', $data);
		$this->load->view('master/kelas/add');
		$this->load->view('_templates/dashboard/_footer');
	}

	public function save() {
		$id = $this->input->post('id_kelas', true);
        $raw_guru = $this->input->post('guru_id', TRUE);
        $guru_id = (!empty($raw_guru)) ? (int)$raw_guru : null;
        
        $active_tp = $this->master->getTahunActive();
		$id_tp = $active_tp ? $active_tp->id_tp : 1;
        $active_smt = $this->master->getSemesterActive();
		$id_smt = $active_smt ? $active_smt->id_smt : 1;
        
        $raw_siswas = $this->input->post('siswa', true);
        $siswas = is_array($raw_siswas) ? array_values($raw_siswas) : [];

        $raw_jurusan = $this->input->post('jurusan_id', TRUE);
        $jurusan_id = (!empty($raw_jurusan) || $raw_jurusan === '0' || $raw_jurusan === 0) ? (int)$raw_jurusan : 0;

        $raw_siswa = $this->input->post('siswa_id', TRUE);
        $siswa_id = (!empty($raw_siswa)) ? (int)$raw_siswa : null;

        $level_id = $this->input->post('level_id', TRUE);
        $level_id = (!empty($level_id)) ? (int)$level_id : 1;

		$config = array(
			array(
				'field' => 'nama_kelas',
				'label' => 'Nama Kelas',
				'rules' => 'trim|required'
			),
            array(
                'field' => 'kode_kelas',
                'label' => 'Kode Kelas',
                'rules' => 'trim'
            ),
			array(
				'field' => 'level_id',
				'label' => 'Level',
				'rules' => 'trim'
			)
		);

        $siswakelas = [];
        foreach ($siswas as $id_s) {
            if (!empty($id_s)) {
                $siswakelas[] = ['id' => $id_s];
            }
        }
        $jumlah = serialize($siswakelas);
        $insert = array(
            'nama_kelas' => $this->input->post('nama_kelas', TRUE),
            'kode_kelas' => $this->input->post('kode_kelas', TRUE),
            'jurusan_id' => $jurusan_id,
            'id_tp' => $id_tp,
            'id_smt' => $id_smt,
            'level_id' => $level_id,
            'guru_id' => $guru_id,
            'siswa_id' => $siswa_id,
            'jumlah_siswa' => $jumlah
        );

        $id_new = null;
        $this->form_validation->set_rules($config);
        if ($this->form_validation->run() == TRUE) {
            if ($id != null && $id != '') {
                $this->db->where('id_kelas', $id);
                $status = $this->db->update('master_kelas', $insert);
            } else {
                $status = $this->db->insert('master_kelas', $insert);
                $id_new = $this->db->insert_id();
            }
        } else {
            $status = FALSE;
        }

		$updated = false;
        $siswa_inserted = 0;
        $target_id_kelas = (!empty($id)) ? $id : $id_new;

        $this->db->query('SET FOREIGN_KEY_CHECKS=0');
		if ($status && !empty($target_id_kelas)) {
            if (!empty($guru_id)) {
                $this->db->set('id_kelas', $target_id_kelas);
                $this->db->where('id_jabatan_guru', $guru_id . $id_tp . $id_smt);
                $updated = $this->db->update('jabatan_guru');
            }

            $insert_siswa = [];
            if ($id != null && $id != '') {
                $siswa_kelas = $this->kelas->get_status_siswa_kelas($id, $id_tp, $id_smt);
                if (is_array($siswa_kelas) && count($siswa_kelas) > 0) {
                    foreach ($siswa_kelas as $id_siswa => $sis) {
                        $insert_siswa[$id_tp . $id_smt . $id_siswa] = [
                            'id_kelas_siswa' => $id_tp . $id_smt . $id_siswa,
                            'id_tp' => $id_tp,
                            'id_smt' => $id_smt,
                            'id_kelas' => 0,
                            'id_siswa' => $id_siswa,
                        ];
                    }
                }
            }

            foreach ($siswas as $idsiswa) {
                if (!empty($idsiswa)) {
                    if (isset($insert_siswa[$id_tp . $id_smt . $idsiswa])) {
                        $insert_siswa[$id_tp . $id_smt . $idsiswa]['id_kelas'] = $target_id_kelas;
                    } else {
                        $insert_siswa[$id_tp . $id_smt . $idsiswa] = [
                            'id_kelas_siswa' => $id_tp . $id_smt . $idsiswa,
                            'id_tp' => $id_tp,
                            'id_smt' => $id_smt,
                            'id_kelas' => $target_id_kelas,
                            'id_siswa' => $idsiswa,
                        ];
                    }
                }
            }

            foreach ($insert_siswa as $ins) {
                if ($this->db->replace('kelas_siswa', $ins)) {
                    $siswa_inserted++;
                }
            }
            $data['insert'] = $insert_siswa;
        }
        $this->db->query('SET FOREIGN_KEY_CHECKS = 1');

        $data['siswa'] = $siswa_inserted;
        $data['update'] = $updated;
		$data['status'] = (bool)$status;
		$this->output_json($data);
	}

	public function update_kelas($id) {
        $active_tp = $this->master->getTahunActive();
		$id_tp = $active_tp ? $active_tp->id_tp : 1;
        $active_smt = $this->master->getSemesterActive();
		$id_smt = $active_smt ? $active_smt->id_smt : 1;
        $siswakelas = $this->kelas->get_status_siswa_kelas($id, $id_tp, $id_smt);

        if (is_array($siswakelas) && count($siswakelas) > 0) {
            foreach ($siswakelas as $id_siswa => $sis) {
                $insert = [
                    'id_kelas_siswa' => $id_tp . $id_smt . $id_siswa,
                    'id_tp' => $id_tp,
                    'id_smt' => $id_smt,
                    'id_kelas' => 0,
                    'id_siswa' => $id_siswa,
                ];
                $this->db->replace('kelas_siswa', $insert);
            }
        }

        $raw_siswa = $this->input->post('siswa', true);
        $siswas = is_array($raw_siswa) ? array_values($raw_siswa) : [];
		for ($i = 0; $i < count($siswas); $i++) {
			$id_siswa = $siswas[$i];
			if (!empty($id_siswa)) {
				$insert = [
					'id_kelas_siswa' => $id_tp . $id_smt . $id_siswa,
					'id_tp' => $id_tp,
					'id_smt' => $id_smt,
					'id_kelas' => $id,
					'id_siswa' => $id_siswa,
				];
				$this->db->replace('kelas_siswa', $insert);
			}
		}
		return $siswakelas;
	}

    public function manage() {
        $user = $this->ion_auth->user()->row();
        $data = [
            'user' => $user,
            'judul' => 'Copy Kelas',
            'subjudul' => 'Copy Data Kelas ke SMT II',
            'setting'		=> $this->dashboard->getSetting(),
        ];

        $tp = $this->dashboard->getTahunActive();
        $smt = $this->dashboard->getSemesterActive();

        $data['tp'] = $this->dashboard->getTahun();
        $data['tp_active'] = $tp;
        $data['smt'] = $this->dashboard->getSemester();
        $data['smt_active'] = $smt;
        $data['profile'] = $this->dashboard->getProfileAdmin($user->id);
        $data['kelas'] = $this->dropdown->getAllKelas($tp->id_tp, '1');
        $data['kelas2'] = $this->dropdown->getAllKelas($tp->id_tp, '2');

        $this->load->view('_templates/dashboard/_header', $data);
        $this->load->view('master/kelas/persemester');
        $this->load->view('_templates/dashboard/_footer');
    }

	public function getFromSmt1($kelas) {
        $tp = $this->dashboard->getTahunActive();
        $data1 = $this->kelas->getKelasSiswa($kelas, $tp->id_tp, '1');
        $data2 = $this->kelas->getKelasSiswa($kelas, $tp->id_tp, '2');

        $ids = [];
        if (count($data2)>0) {
            foreach ($data2 as $s) {
                $ids[] = $s->id_siswa;
            }
        }
        $this->output_json(['smt1'=>$data1, 'smt2'=>$ids]);
    }

    public function copyFromSmt1() {
        $tp = $this->dashboard->getTahunActive();
        $smt = $this->dashboard->getSemesterActive();
        $kelas1 = $this->input->post('kelas_lama', true);
        $kelas2 = $this->input->post('kelas_baru', true);

        $kelas = $this->kelas->get_one($kelas1, $tp->id_tp, '1');
        $data = array(
            'nama_kelas' => $kelas2,
            'kode_kelas' => $kelas->kode_kelas,
            'jurusan_id' => $kelas->jurusan_id,
            'id_tp' => $tp->id_tp,
            'id_smt' => $smt->id_smt,
            'level_id' => $kelas->level_id,
            'guru_id' => $kelas->guru_id,
            'siswa_id' => $kelas->siswa_id,
            'jumlah_siswa' => $kelas->jumlah_siswa
        );

        //$res = $this->master->create('master_kelas', $data, false);
        $this->db->insert('master_kelas', $data);
        $idk = $this->db->insert_id();

        $res = [];
        $arrSiswa = unserialize($kelas->jumlah_siswa);
        foreach ($arrSiswa as $value) {
            $id_siswa = $value['id'];
            if ($id_siswa!=null) {
                $insert = [
                    'id_kelas_siswa' => $tp->id_tp . $smt->id_smt . $id_siswa,
                    'id_tp' => $tp->id_tp,
                    'id_smt' => $smt->id_smt,
                    'id_kelas' => $idk,
                    'id_siswa' => $id_siswa,
                ];
                $res[] = $this->db->replace('kelas_siswa', $insert);
            }
        }
        $this->output_json($res);
    }

    public function copySiswaFromSmt1() {
        $tp = $this->dashboard->getTahunActive();
        $smt = $this->dashboard->getSemesterActive();
        $posts = json_decode($this->input->post('kelas', true));

        $idkelases = [];
        $siswakelas = [];
        foreach ($posts as $d) {
            $idkelases[] = $d->id_kelas;
            $siswakelas[$d->id_kelas][] = [
                'id' => $d->id_siswa
            ];
        }
        $idkelases = array_unique($idkelases);

        $res = [];
        foreach ($idkelases as $ik) {
            if ($ik != '') {
                $kelas = $this->kelas->get_one($ik, $tp->id_tp, '1');

                $jumlah = serialize($siswakelas[$ik]);
                $data = array(
                    'nama_kelas' => $kelas->nama_kelas,
                    'kode_kelas' => $kelas->kode_kelas,
                    'jurusan_id' => $kelas->jurusan_id,
                    'id_tp' => $tp->id_tp,
                    'id_smt' => $smt->id_smt,
                    'level_id' => $kelas->level_id,
                    'guru_id' => $kelas->guru_id,
                    'siswa_id' => $kelas->siswa_id,
                    'jumlah_siswa' => $jumlah
                );
                $this->db->insert('master_kelas', $data);
                $idk = $this->db->insert_id();

                foreach ($siswakelas[$ik] as $s) {
                    $insert = [
                        'id_kelas_siswa' => $tp->id_tp . $smt->id_smt . $s['id'],
                        'id_tp' => $tp->id_tp,
                        'id_smt' => $smt->id_smt,
                        'id_kelas' => $idk,
                        'id_siswa' => $s['id'],
                    ];
                    $res[] = $this->db->replace('kelas_siswa', $insert);
                }
            }
        }
        $this->output_json($res);
    }

    public function kenaikan() {
        $kelas = $this->input->get('kelas', true);
        $user = $this->ion_auth->user()->row();
        $setting = $this->dashboard->getSetting();
        $data = [
            'user' => $user,
            'judul' => 'Kenaikkan Kelas',
            'subjudul' => 'Naik Kelas Siswa',
            'setting'		=> $setting,
        ];

        $tp = $this->dashboard->getTahunActive();
        $smt = $this->dashboard->getSemesterActive();

        $data['tp'] = $this->dashboard->getTahun();
        $data['tp_active'] = $tp;
        $data['smt'] = $this->dashboard->getSemester();
        $data['smt_active'] = $smt;
        $data['profile'] = $this->dashboard->getProfileAdmin($user->id);

        $level = $setting->jenjang == '1' ? '6' : ($setting->jenjang == '2' ? '9' : ($setting->jenjang == '1' ? '3' : '12'));
        $data['kelas_lama'] = $this->dropdown->getAllKelas(($tp->id_tp) - 1, '2', '!='.$level);
        $data['kelas_baru'] = $this->dropdown->getAllKelas($tp->id_tp, '1');

        if ($kelas != null) {
            $data['siswa_kelas_baru'] = $this->master->getSiswaKelasBaru($tp->id_tp, $smt->id_smt);

            $data['siswas'] = $this->rapor->getKenaikanSiswa($kelas, ($tp->id_tp) - 1, '2');
            $data['kelas_selected'] = $kelas;

            $lvlKls = $this->kelas->get_one($kelas, ($tp->id_tp) - 1, '2');
            $data['kelases'] = $this->dropdown->getAllKelas(($tp->id_tp) - 1, '2', '='.(($lvlKls->level_id)+1));
        }

        $this->load->view('_templates/dashboard/_header', $data);
        $this->load->view('master/kelas/naikkelas');
        $this->load->view('_templates/dashboard/_footer');
    }

    public function naikKelas() {
        $tp = $this->dashboard->getTahunActive();
        $smt = $this->dashboard->getSemesterActive();
        $posts = json_decode($this->input->post('kelas', true));
        $mode = $this->input->post('mode', true);

        $idkelases = [];
        $siswakelas = [];
        foreach ($posts as $d) {
            $idkelases[] = $d->kelas_baru;
            $siswakelas[$d->kelas_baru][] = ['id' => $d->id_siswa];
        }

        $idkelases = array_unique($idkelases);

        $res = [];
        $idks = [];
        foreach ($idkelases as $ik) {
            $kelas = $this->kelas->get_one($ik, ($tp->id_tp)-1, '2');
            //$kelasBaru = $this->kelas->get_one($ik, $tp->id_tp, $smt->id_smt);
            $kelas_baru = $this->kelas->getKelasByNama($kelas->nama_kelas, $tp->id_tp, $smt->id_smt);

            if ($kelas_baru == null) {
                $jumlah = serialize($siswakelas[$ik]);
                $data = array(
                    'nama_kelas' => $kelas->nama_kelas,
                    'kode_kelas' => $kelas->kode_kelas,
                    'jurusan_id' => $kelas->jurusan_id,
                    'id_tp' => $tp->id_tp,
                    'id_smt' => $smt->id_smt,
                    'level_id' => $kelas->level_id,
                    'guru_id' => $kelas->guru_id,
                    'siswa_id' => $kelas->siswa_id,
                    'jumlah_siswa' => $jumlah
                );
                $this->db->insert('master_kelas', $data);
                //$idk = $this->db->insert_id();
                array_push($idks, $this->db->insert_id());
            } else {
                if ($mode == 'persiswa') {
                    $jmlLama = unserialize($kelas_baru->jumlah_siswa);
                    foreach ($siswakelas[$ik] as $s) {
                        foreach ($jmlLama as $lama) {
                            if ($lama['id'] != $s['id']) {
                                array_push($jmlLama, ['id' => $s['id']]);
                                array_push($idks, $kelas_baru->id_kelas);
                            }
                        }
                    }
                    $jumlah = serialize($jmlLama);
                } else {
                    $jumlah = serialize($siswakelas[$ik]);
                    array_push($idks, $kelas_baru->id_kelas);
                }

                $data = array(
                    'nama_kelas' => $kelas->nama_kelas,
                    'kode_kelas' => $kelas->kode_kelas,
                    'jurusan_id' => $kelas->jurusan_id,
                    'id_tp' => $tp->id_tp,
                    'id_smt' => $smt->id_smt,
                    'level_id' => $kelas->level_id,
                    'guru_id' => $kelas->guru_id,
                    'siswa_id' => $kelas->siswa_id,
                    'jumlah_siswa' => $jumlah
                );

                $this->db->where('id_kelas', $kelas_baru->id_kelas);
                $this->db->update('master_kelas', $data);
            }

            foreach ($idks as $idk) {
                foreach ($siswakelas[$ik] as $s) {
                    $insert = [
                        'id_kelas_siswa' => $tp->id_tp . $smt->id_smt . $s['id'],
                        'id_tp' => $tp->id_tp,
                        'id_smt' => $smt->id_smt,
                        'id_kelas' => $idk,
                        'id_siswa' => $s['id'],
                    ];
                    $res[] = $this->db->replace('kelas_siswa', $insert);
                }
            }
        }

        $data['res'] = $siswakelas;
        $this->output_json($data);
    }

    public function hapus($id_kelas) {
        //$delete['siswa'] = $this->master->delete('kelas_siswa', [$id_kelas, '0'], 'id_kelas');
        $delete['siswa'] = $this->master->delete('kelas_siswa', $id_kelas, 'id_kelas');
        $delete['kelas'] = $this->master->delete('master_kelas', $id_kelas, 'id_kelas');
        $this->output_json($delete);
    }
}
