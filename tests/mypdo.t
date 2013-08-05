#!/usr/bin/env php
<?php
use Wukka\Test as T;
use Wukka\DB;

include __DIR__ . '/../autoload.php';
include __DIR__ . '/../assert/pdo_installed.php';
include __DIR__ . '/../assert/pdo_mysql_installed.php';
include __DIR__ . '/../assert/mysql_running.php';

$instance = function(){
    return include __DIR__ . '/mypdo.connection.php';
};

try {
    $db = $instance();
} catch( Exception $e ){
    T::plan('skip_all', $e->__toString());
}

include __DIR__ . '/injection.mysql.php';
