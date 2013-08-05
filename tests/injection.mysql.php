<?php
use Wukka\Test as T;
use Wukka\DB;
use Wukka\DB\Transaction;

$original = $db;


T::plan(51);
$db = new DB($db);

T::is( spl_object_hash($original), $db->hash(), 'the hash function returns the hash of the original db object');

DB\Connection::load( array( 'test'=> function() use( $db ){ return $db; }));

T::ok( DB\Connection::instance('test') === $db, 'db instance returns same object we instantiated at first');

T::is( $db->isa('mysql'), TRUE, 'driver is mysql');

$rs = $db->execute('SELECT %s as foo, %s as bar', 'dummy\'', 'rummy');
T::ok( $rs, 'query executed successfully');
T::is($rs->fetch(), array('foo'=>'dummy\'', 'bar'=>'rummy'), 'sql query preparation works on strings');

$rs = $db->execute('SELECT %i as test', '1112122445543333333333');
T::is( $rs->fetch(), array('test'=>'1112122445543333333333'), 'query execute works injecting big integer in');

$rs = $db->execute('SELECT %i as test', 'dummy');
T::is( $rs->fetch(), array('test'=>'0'), 'query execute sanitizes non integer');

$rs = $db->execute('SELECT %f as test', '1112.122445543333333333');
T::is( $rs->fetch(), array('test'=>'1112.122445543333333333'), 'query execute works injecting big float in');

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

T::like( $db->error(), '/you have an error in your sql syntax/i', '$db->error() returns error message');

T::is( $db->errorcode(), 1064, 'returns expected mysql error code');

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

$rs = $db->execute("SELECT 'test' as r1");
T::is( $rs->affected(), 1, 'selected a row, affected rows is one');

$newconn = function() use( $instance ){
    return new DB( $instance() );
};


$table = 'test_' . time() . '_' . mt_rand(10000, 99999);


$dbmain = $newconn();
$dbmain->execute("create table $table (id int unsigned not null primary key) engine=innodb");
$conn1 = $newconn();
$conn2 = $newconn();


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

T::ok($rs = $dbmain->execute("select id from $table"), 'selected all rows from the table');
$ct = $rs->affected();
T::is($ct, 0, 'no rows in the table');
//if( ! $rs ) T::debug( $conn1 );

Transaction::reset();

$conn1 = $newconn();
$conn2 = $newconn();
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


T::ok($rs = $dbmain->execute("select id from $table"), 'selected all rows from the table');
$ct = $rs->affected();
T::is($ct, 2, '2 rows in the table');
//var_dump( $rs );
//var_dump( $conn1 );

Transaction::reset();

T::ok(Transaction::start(), 'started a transaction at the global level');

$conn1 = $newconn();
$conn2 = $newconn();
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

T::ok($rs = $dbmain->execute("select id from $table"), 'selected all rows from the table');
$ct = $rs->affected();
T::is($ct, 2, '2 rows in the table, new rows rolled back');

$rs = $conn1->execute("select id from $table");
T::is( $rs, FALSE, 'after rolling back, new queries fail on rolled back db object');


$dbmain->execute("drop table $table");


$db = $newconn();

$raw = file_get_contents(__DIR__ . '/sample/i_can_eat_glass.txt');

$lines = explode("\n", $raw);
$lines = array_slice($lines, 0, 10) + array_slice($lines, 100, 10) + array_slice($lines, 200, 10) + array_slice($lines, 200, 10);
$raw = implode("\n", $lines);
$sql = "CREATE TEMPORARY TABLE t1utf8 (`i` INT UNSIGNED NOT NULL PRIMARY KEY, `line` VARCHAR(5000) ) ENGINE=InnoDB DEFAULT CHARACTER SET utf8";
$db->execute($sql);

foreach($lines as $i=>$line ){
    //$lines[ $i ] = $line = mb_convert_encoding($line, 'UTF-8', 'auto');
    $db->execute('INSERT INTO t1utf8 (`i`, `line`) VALUES (%i, %s)', $i, $line);
}


$rs = $db->execute('SELECT * FROM t1utf8');
$readlines = array();
while( $row = $rs->fetch() ){
    $readlines[ $row['i'] ] = $row['line'];
}
$rs->free();

T::cmp_ok( $readlines, '===', $lines, 'inserted all the rows and read them back, worked as expected');
//T::debug( $readlines );



$rs = $db->execute('SELECT %s AS `d`', $raw);
$row = $rs->fetch();
$rs->free();

T::cmp_ok( $row['d'], '===', $raw, 'passed a huge chunk of utf-8 data to db and asked for it back. got what I sent.');
//T::debug( $row['d'] );


