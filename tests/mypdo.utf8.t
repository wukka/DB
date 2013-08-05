#!/usr/bin/env php
<?php
use Wukka\Test as T;
use Wukka\DB;

include __DIR__ . '/../autoload.php';
include __DIR__ . '/../assert/pdo_installed.php';
include __DIR__ . '/../assert/pdo_mysql_installed.php';
include __DIR__ . '/../assert/mysql_running.php';


$raw = file_get_contents(__DIR__ . '/sample/i_can_eat_glass.txt');

$db = new DB(include __DIR__ . '/mypdo.connection.php');

T::plan(153);
$lines = explode("\n", $raw);
$sql = "CREATE TEMPORARY TABLE t1utf8 (`i` INT UNSIGNED NOT NULL PRIMARY KEY, `line` VARCHAR(5000) ) ENGINE=InnoDB DEFAULT CHARACTER SET utf8";
$db->execute($sql);

foreach($lines as $i=>$line ){
    $db->execute('INSERT INTO t1utf8 (`i`, `line`) VALUES (%i, %s)', $i, $line);
    $rs = $db->execute('SELECT %s AS `line`', $line );
    $row = $rs->fetch();
    $rs->free();
    T::cmp_ok($row['line'], '===', $line, 'sent to mysql and read it back: ' . $line );
}


$rs = $db->execute('SELECT * FROM t1utf8');
$readlines = array();
while( $row = $rs->fetch() ){
    $readlines[ $row['i'] ] = $row['line'];
}
$rs->free();

T::cmp_ok( $readlines, '===', $lines, 'inserted all the rows and read them back, worked as expected');
//T::debug( $readlines );

$raw = file_get_contents(__DIR__ . '/sample/UTF-8-test.txt');


$rs = $db->execute('SELECT %s AS `d`', $raw);
$row = $rs->fetch();
$rs->free();

T::cmp_ok( $row['d'], '===', $raw, 'passed a huge chunk of utf-8 data to mysql and asked for it back. got what I sent.');
//T::debug( $row['d'] );
