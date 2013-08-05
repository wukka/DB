#!/usr/bin/env php
<?php
use Wukka\Test as T;
use Wukka\DB;

include __DIR__ . '/../autoload.php';
include __DIR__ . '/../assert/mysqli_installed.php';
include __DIR__ . '/../assert/mysql_running.php';

$instance = function(){
    return include __DIR__ . '/mysqli.connection.php';
};
$db = $instance();
if( $db->connect_error ){
    T::plan('skip_all', 'mysqli: ' . $db->connect_error );
}

include __DIR__ . '/injection.mysql.php';
