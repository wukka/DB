#!/usr/bin/env php
<?php
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
T::plan(13);

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

$db = new DB\Except( $db );

$err = NULL;
try {
    $db->execute('err');
} catch( Exception $e ){
    $err = (string) $e;
}

T::like($err, '/database error/i', 'When a bad query is run using execute() the except wrapper tosses an exception');

$db = new DB\Observe( $db );
T::is( $db->isa('pdo'), TRUE, 'isa returns true for inner class');
T::is( $db->isa('wukka\db'), TRUE, 'isa returns true for wukka\db');

