#!/usr/bin/env php
<?php
include __DIR__ . '/../autoload.php';

use Wukka\Test as T;
use Wukka\DB;

include __DIR__ . '/../autoload.php';
include __DIR__ . '/../assert/pdo_installed.php';
include __DIR__ . '/../assert/pdo_pgsql_installed.php';
include __DIR__ . '/../assert/postgres_running.php';

try {
   $db = new DB( include __DIR__ . '/pgpdo.connection.php' );
} catch( \Exception $e ){
    T::plan('skip_all', $e->__toString());
}

$raw = file_get_contents(__DIR__ . '/sample/i_can_eat_glass.txt');


T::plan(152);
$lines = explode("\n", $raw);
$sql = "CREATE TEMPORARY TABLE t1utf8 (i INT NOT NULL PRIMARY KEY, line VARCHAR(5000) )";
$rs = $db->execute($sql);

foreach($lines as $i=>$line ){
    $db->execute('INSERT INTO t1utf8 (i, line) VALUES (%i, %s)', $i, $line);
    $rs = $db->execute('SELECT %s AS line', $line );
    $row = $rs->fetch();
    $rs->free();
    T::cmp_ok($row['line'], '===', $line, 'sent to db and read it back: ' . $line );
}


$rs = $db->execute('SELECT * FROM t1utf8');
$readlines = array();
while( $row = $rs->fetch() ){
    $readlines[ $row['i'] ] = $row['line'];
}
$rs->free();

T::cmp_ok( $readlines, '===', $lines, 'inserted all the rows and read them back, worked as expected');
//T::debug( $readlines );

T::debug('TODO: get more complex tests from utf-8 working');
/*
$raw = file_get_contents(__DIR__ . '/../sample/UTF-8-test.txt');

foreach(explode("\n", $raw) as $i=>$line ){
    $rs = $db->execute('SELECT %s AS line', $line );
    $row = $rs->fetch();
    $rs->free();
    T::cmp_ok($row['line'], '===', $line, 'sent to sqlite and read it back: ' . $line );

}
*/