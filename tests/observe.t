#!/usr/bin/env php
<?php
use Wukka\Test as T;
use Wukka\DB;

include __DIR__ . '/../autoload.php';


T::plan(6);

$db = new DB\Callback( array('execute'=>function($query){
    return new DB\StaticResult( array(array('foo'=>'dummy\'', 'bar'=>'rummy')  ) );
}));

$fd = fopen('php://memory', 'w+');

$a = null;
$r = NULL;
$o = new DB\Observe( $db, array('execute'=>
    function( $args, $result ) use ( &$a, &$r, $fd) {
        $a = $args;
        $r = $result;
        fwrite( $fd, 'db query: ' . $args[0]);
    }
));


$rs = $o->execute('SELECT %s as foo, %s as bar', 'dummy\'', 'rummy');
T::ok( $rs, 'query executed successfully');
T::is( $rs, $r, 'result object passed back to the callback');
T::is( $a, array( 'SELECT %s as foo, %s as bar', 'dummy\'', 'rummy'), 'got method args passed to the callback too');

T::is( $o->isa('Wukka\DB\Observe'), TRUE, 'wrapper tells us isa about itself');
T::is( $o->isa('Wukka\DB\Callback'), TRUE, 'wrapper tells us the core instanceof');
T::is( $o->isa('Wukka\DB\Transaction'), FALSE, 'doesnt false report instanceof');
