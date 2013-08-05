#!/usr/bin/env php
<?php
use Wukka\Test as T;
use Wukka\DB;

include __DIR__ . '/../autoload.php';
include __DIR__ . '/../assert/mysqli_installed.php';
include __DIR__ . '/../assert/pdo_installed.php';

T::plan(6);

$db = new DB\Except( $mock = new DB\Callback());

$err = '';

$debug = null;

try {
    $db->execute('test');
} catch( Exception $e ){
    $err = (string) $e;
    $debug = $e->getDebug();
}

T::like( $err, '/database error/i', 'except wrapping db object, on query failure an exception is thrown');
T::is( $debug, array('db'=>$mock, 'query'=>'test', 'exception'=>null), 'debug attached properly to exception');


$db = new DB\Except( $mock = new DB\Callback(array('execute'=> function($query){
    return TRUE;
})));

$err = '';

$debug = null;

try {
    $db->execute('test');
} catch( Exception $e ){
    $err = (string) $e;
    $debug = $e->getDebug();
}

T::is( $err, '', 'no exception thrown when query runs properly');

T::is( $db->isa('Wukka\DB\Callback'), TRUE, 'expect is a wrapper and tells us the core instanceof');
T::is( $db->isa('Wukka\DB\Transaction'), FALSE, 'doesnt false report instanceof');

$sql = $db->prep( '%i %s', 1, 'test');

T::is( $sql, "1 'test'", 'SQL prep works properly' );

//print $err;