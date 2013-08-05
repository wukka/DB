#!/usr/bin/env php
<?php
use Wukka\Test as T;
use Wukka\DB;
use Wukka\DB\Transaction;

include __DIR__ . '/../autoload.php';
include __DIR__ . '/../assert/mysqli_installed.php';
include __DIR__ . '/../assert/mysql_running.php';


T::plan(28);
$table = 'test_' . time() . '_' . mt_rand(10000, 99999);

$dbmain = new DB ( include __DIR__ . '/mysqli.connection.php' );
$dbmain->execute("create table $table (id int unsigned not null primary key) engine=innodb");
$conn1 = new DB( include __DIR__ . '/mysqli.connection.php' );
$conn2 = new DB(  include __DIR__ . '/mysqli.connection.php'  );


T::ok( $conn1 !== $conn2, 'created two db objects');
$rs = $conn1->execute('SELECT CONNECTION_ID() as id');
$row = $rs->fetch();
$id1= $row['id'];

$rs = $conn2->execute('SELECT CONNECTION_ID() as id');
$row = $rs->fetch();
$id2= $row['id'];

T::isnt( $id1, $id2, 'got back connection ids from each and they arent the same');
T::ok($conn1->start(), 'started a transaction on conn1');
T::ok($conn2->start(), 'started a transaction on conn2');

$rs = $conn1->execute("insert into $table values (1)");
T::ok( $rs, 'inserted a row into test table from conn1');
//if( ! $rs ) T::debug( $conn1 );

$rs = $conn2->execute("insert into $table values(2)");
T::ok( $rs, 'inserted a row into test table from conn2');
//if( ! $rs ) T::debug( $conn2 );

T::ok( $rs = $conn1->commit(), 'committed inserted row on conn1');
//if( ! $rs ) T::debug( $conn1 );

T::ok( $rs = $conn2->rollback(), 'rolled back row on conn2');
//if( ! $rs ) T::debug( $conn2 );

T::ok($res = $dbmain->execute("select id from $table"), 'selected all rows from the table');
$ct = $res->affected();
T::is($ct, 0, 'no rows in the table');
//if( ! $rs ) T::debug( $conn1 );

Transaction::reset();

$conn1 = new DB(  include __DIR__ . '/mysqli.connection.php' );
$conn2 = new DB(  include __DIR__ . '/mysqli.connection.php' );
T::ok($conn1->start(), 'started a transaction on conn1');
T::ok($conn2->start(), 'started a transaction on conn2');

$rs = $conn1->execute("insert into $table values (1)");
T::ok( $rs, 'inserted a row into test table from conn1');
//if( ! $rs ) T::debug( $conn1 );

$rs = $conn2->execute("insert into $table values(2)");
T::ok( $rs, 'inserted a row into test table from conn2');
//if( ! $rs ) T::debug( $conn2 );

T::ok( $conn1->commit(), 'committed inserted row on conn1');

T::ok( $conn2->commit(), 'committed inserted row on conn2');


T::ok($res = $dbmain->execute("select id from $table"), 'selected all rows from the table');
$ct = $res->affected();
T::is($ct, 2, '2 rows in the table');
//var_dump( $rs );
//var_dump( $conn1 );

Transaction::reset();

T::ok(Transaction::start(), 'started a transaction at the global level');

$conn1 = new DB(  include __DIR__ . '/mysqli.connection.php' );
$conn2 = new DB(  include __DIR__ . '/mysqli.connection.php' );
$conn2 = new DB(  include __DIR__ . '/mysqli.connection.php' );
T::ok($conn1->start(), 'started a transaction on conn1');
T::ok($conn2->start(), 'started a transaction on conn2');

$rs = $conn1->execute("insert into $table values (3)");
T::ok( $rs, 'inserted a row into test table from conn1');
//if( ! $rs ) T::debug( $conn1 );

$rs = $conn2->execute("insert into $table values(4)");
T::ok( $rs, 'inserted a row into test table from conn2');
//if( ! $rs ) T::debug( $conn2 );

T::ok( $conn1->commit(), 'committed inserted row on conn1');

T::ok( $conn2->commit(), 'committed inserted row on conn2');

T::ok( Transaction::rollback(), 'rolled back the transaction at the global level');

T::ok($res = $dbmain->execute("select id from $table"), 'selected all rows from the table');
$ct = $res->affected();
T::is($ct, 2, '2 rows in the table, new rows rolled back');


$dbmain->execute("drop table $table");
