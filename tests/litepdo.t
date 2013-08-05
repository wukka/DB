#!/usr/bin/env php
<?php
use Wukka\Test as T;
use Wukka\DB;
use Wukka\DB\Transaction;

include __DIR__ . '/../autoload.php';
include __DIR__ . '/../assert/pdo_installed.php';
include __DIR__ . '/../assert/pdo_sqlite_installed.php';

$instance = function(){
    return new \PDO('sqlite::memory:');
};

try {
    $db = $instance();
} catch( Exception $e ){
    T::plan('skip_all', $e->__toString());
}


$original = $db;


T::plan(26);
$db = new DB($db);

DB\Connection::load( array( 'test'=> function() use( $db ){ return $db; }));

T::ok( DB\Connection::instance('test') === $db, 'db instance returns same object we instantiated at first');

$rs = $db->execute('SELECT %s as foo, %s as bar', 'dummy\'', 'rummy');
T::ok( $rs, 'query executed successfully');
T::is($rs->fetch(), array('foo'=>'dummy\'', 'bar'=>'rummy'), 'sql query preparation works on strings');

$rs = $db->execute('SELECT %i as test', '111212244554333');
T::is( $rs->fetch(), array('test'=>'111212244554333'), 'query execute works injecting big integer in');

$rs = $db->execute('SELECT %i as test', 'dummy');
T::is( $rs->fetch(), array('test'=>'0'), 'query execute sanitizes non integer');

$rs = $db->execute('SELECT %f as test', '1112.1224455433');
T::is( $rs->fetch(), array('test'=>'1112.1224455433'), 'query execute works injecting big float in');

$rs = $db->execute('SELECT %f as test', 'dummy');
T::is( $rs->fetch(), array('test'=>'0'), 'query execute sanitizes non float');

$query = $db->prep('%s', array('dummy', 'rummy'));
T::is($query, "'dummy', 'rummy'", 'format query handles arrays of strings');

$query = $db->prep('%i', array(1,2,3));
T::is($query, '1, 2, 3', 'format query handles arrays of integers');

$query = $db->prep('%f', array(1.545,2.2,3));
T::is($query, '1.545, 2.2, 3', 'format query handles arrays of floats');


$query = $db->prep('test %%s ?, (?,?)', array(1, 2), 3, 4);
T::is($query, "test %s '1', '2', ('3','4')", 'format query question mark as string');

$rs = $db->execute('err');

T::cmp_ok( $rs, '===', FALSE, 'db returns false on query error');

T::like( $db->error(), '/syntax/i', '$db->error() returns error message');

T::is( $db->errorcode(), 1, 'returns expected error code');

$db = new DB\Except( DB\Connection::instance('test') );

$err = NULL;
try {
    $db->execute('err');
} catch( Exception $e ){
    $err = (string) $e;
}

T::like($err, '/database error/i', 'When a bad query is run using execute() the except wrapper tosses an exception');


T::is( $db->isa(get_class($original)), TRUE, 'isa returns true for original object');
T::is( $db->isa('wukka\db'), TRUE, 'isa returns true for wukka\db');

$newconn = function() use( $instance ){
    return new DB( $instance() );
};

Transaction::reset();
$table = 'test_' . time() . '_' . mt_rand(10000, 99999);


$db = $newconn();
$db->execute("create table $table (id int unsigned not null primary key)");


T::ok($db->start(), 'started a transaction');

$rs = $db->execute("insert into $table values (1)");
T::ok( $rs, 'inserted a row into test table');
//if( ! $rs ) T::debug( $conn1 );

T::ok( $rs = $db->commit(), 'committed inserted row');
//if( ! $rs ) T::debug( $conn1 );

T::ok($rs = $db->execute("select id from $table"), 'selected all rows from the table');
$ct = count( $rs->all());
T::is($ct, 1, '1 row in the table');
//if( ! $rs ) T::debug( $conn1 );

//Transaction::reset();


$db->start();

$rs = $db->execute("insert into $table values (2)");
T::ok( $rs, 'inserted a row into test table');
//if( ! $rs ) T::debug( $conn1 );

//if( ! $rs ) T::debug( $conn2 );

T::ok( $db->rollback(), 'rolled back inserted row');


$db = new DB( $db->core() );
T::ok($rs = $db->execute("select id from $table"), 'selected all rows from the table');
$ct = count( $rs->all() );
T::is($ct, 1, '1 row in the table');
//var_dump( $rs );
//var_dump( $conn1 );


$db->execute("drop table $table");




