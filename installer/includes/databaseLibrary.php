<?php

class Database {

    function create_database($data) {
        $mysqli = @new mysqli($data['hostname'], $data['username'], $data['password'], '');
        if ($mysqli->connect_errno) return false;

        $dbName = preg_replace('/[^a-zA-Z0-9_]/', '', $data['database']);
        if (empty($dbName)) {
            $mysqli->close();
            return false;
        }

        $res = $mysqli->query("CREATE DATABASE IF NOT EXISTS `$dbName` CHARACTER SET utf8 COLLATE utf8_general_ci");
        $mysqli->close();
        return $res ? true : false;
    }

    function create_tables($data) {
        $mysqli = @new mysqli($data['hostname'], $data['username'], $data['password'], $data['database']);
        if ($mysqli->connect_errno) return false;

        $check = $mysqli->query("SHOW TABLES LIKE 'users'");
        if ($check && $check->num_rows > 0) {
            $check->close();
            $mysqli->close();
            return true;
        }
        if ($check) $check->close();

        $sql_path = '../assets/app/db/master.sql';
        if (!file_exists($sql_path)) {
            $mysqli->close();
            return false;
        }

        $query = file_get_contents($sql_path);
        if ($mysqli->multi_query($query)) {
            do {
                if ($result = $mysqli->store_result()) {
                    $result->free();
                }
            } while ($mysqli->more_results() && $mysqli->next_result());
        }

        // Verify users table was created
        $verify = $mysqli->query("SHOW TABLES LIKE 'users'");
        $success = ($verify && $verify->num_rows > 0);
        if ($verify) $verify->close();
        $mysqli->close();

        return $success;
    }
}
