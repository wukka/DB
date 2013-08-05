#!/usr/bin/env php
<?php
use Wukka\Test as T;
use Wukka\DB;
use Wukka\DB\Transaction;

include __DIR__ . '/../autoload.php';
T::plan(14);

$commit = $rollback = 0;
$commit_handler = function( $var = 0 ) use ( & $commit ){ $commit+= $var;};
$rollback_handler = function($var = 0) use ( & $rollback ){$rollback+=$var;};


T::is(Transaction::start(), TRUE, 'started a transaction');
T::ok( Transaction::inProgress(), 'transaction in progress');

Transaction::onCommit( $commit_handler, array(5) );
Transaction::onCommit( $commit_handler, array(5) );
Transaction::onCommit( $commit_handler, array(1) );
Transaction::onRollback( $rollback_handler, array(5) );
Transaction::onRollback( $rollback_handler, array(5) );
Transaction::onRollback( $rollback_handler, array(1) );

T::is( Transaction::commit(), TRUE, 'commited the transaction');

T::is($commit, 6, 'commit handler triggered with correct params');
T::is($rollback, 0, 'rollback handler not touched');

$commit = 0;
$rollback = 0;

T::ok( ! Transaction::inProgress(), 'transaction no longer in progress');

T::is(Transaction::start(), TRUE, 'started a new transaction');
T::is( Transaction::commit(), TRUE, 'commited the transaction');

T::is($commit, 0, 'commit handler not triggered, not attached');
T::is($rollback, 0, 'rollback handler not touched');


$commit = 0;
$rollback = 0;


T::is(Transaction::start(), TRUE, 'started a new transaction');
Transaction::onCommit( $commit_handler, array(5) );
Transaction::onCommit( $commit_handler, array(5) );
Transaction::onCommit( $commit_handler, array(1) );
Transaction::onRollback( $rollback_handler, array(5) );
Transaction::onRollback( $rollback_handler, array(5) );
Transaction::onRollback( $rollback_handler, array(1) );
T::is( Transaction::rollback(), TRUE, 'rolled back the transaction');
T::is($rollback, 6, 'rollback handler triggered with correct params');
T::is($commit, 0, 'commit handler not touched');
