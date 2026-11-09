<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Created by IntelliJ IDEA.
 * User: ServerMts
 * Date: 18/12/2021
 * Time: 15:45
 */

class Migrate extends CI_Controller{

    public function __construct() {
        parent::__construct();
        if (!$this->ion_auth->logged_in() || !$this->ion_auth->is_admin()) {
            redirect('auth');
        }
    }

    public function index(){
        echo 'Controller file index method run.';
        /*
        $this->load->library('migration');

        if ($this->migration->current() === FALSE) {
            show_error($this->migration->error_string());
        }
        */
    }

    public function CreateMigration($version = '20230902000000'){
        $this->load->library('migration');
        if ($this->migration->current() === FALSE) {
            show_error($this->migration->error_string());
        } else {
            echo 'The migration file has executed successfully.';
        }
        /*
        if(isset($version) && ($this->migration->version($version) === FALSE)){
            show_error($this->migration->error_string());
        } elseif(is_null($version) && $this->migration->latest() === FALSE){
            show_error($this->migration->error_string());
        } else {
            echo 'The migration file has executed successfully.';
        }*/
    }

    public function undoMigration($version = NULL){
        $this->load->library('migration');
        $migrations = $this->migration->find_migrations();
        $migrationKeys = array();
        foreach($migrations as $key => $migration){
            $migrationKeys[] = $key;
        }
        if(isset($version) && array_key_exists($version,$migrations) && $this->migration->version($version)){
            echo 'The migration was undo';
            exit;
        } elseif(isset($version) && !array_key_exists($version,$migrations)){
            echo 'The migration with selected version doesn’t exist.';
        } else {
            $penultimate = (sizeof($migrationKeys)==1) ? 0 : $migrationKeys[sizeof($migrationKeys) - 2];
            if($this->migration->version($penultimate)){
                echo 'The migration has been reverted successfully.';
                exit;
            } else {
                echo 'Couldn\’t roll back the migration.';
                exit;
            }
        }
    }

    public function resetMigration(){
        $this->load->library('migration');
        if($this->migration->current()!== FALSE){
            echo 'The migration was revert to the version set in the config file.';
            return TRUE;
        } else {
            echo 'Couldn\’t reset migration.';
            show_error($this->migration->error_string());
            exit;
        }
    }

    function make_base(){

        $this->load->library('ci_migrations_generator/Sqltoci');

        // All Tables:
        //$this->sqltoci->generate();

        //Single Table:
        $this->sqltoci->generate('kelas_jadwal_kbm');

    }
}