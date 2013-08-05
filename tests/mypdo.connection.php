<?php
$host = ini_get('mysqli.default_host');
if( ! $host ) $host = '127.0.0.1';
$user = ini_get('mysqli.default_user');
if( ! $user ) $user = get_current_user();
$pass = ini_get('mysqli.default_pass');
$port = ini_get('mysqli.default_port');
if( ! $port ) $port = 3306;
$dbname='test';

return new PDO("mysql:host=$host;dbname=$dbname;port=$port", $user, $pass );